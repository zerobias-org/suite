import com.zerobias.buildtools.content.SchemaPrimitives

plugins {
    id("zb.workspace")
}

group = "com.zerobias.content"

/**
 * Mirrors the dataloader's URL validation: `new URL(value)` from
 * `@zerobias-org/types-core-js`. Strings must parse as absolute URLs
 * with a scheme + host.
 */
fun requireUrlFormat(value: Any?, field: String, tag: String) {
    require(value is String && value.isNotBlank()) { "$tag $field must be a non-blank string" }
    try {
        val uri = java.net.URI(value)
        require(uri.scheme != null && uri.host != null) {
            "$tag $field must be an absolute URL (scheme + host): got '$value'"
        }
    } catch (e: Exception) {
        throw IllegalArgumentException("$tag $field is not a valid URL: $value (${e.message})")
    }
}

// ════════════════════════════════════════════════════════════
// Suite schema validator — owned by this repo.
//
// Mirrors com/platform/dataloader/src/processors/suite/SuiteFileHandler.ts
// so failures shift left from prod load to gate time. Suites live at
// package/<vendorCode>/<suiteCode>/ and the dataloader links each one
// to its parent vendor by id+code on load.
// ════════════════════════════════════════════════════════════
extra["contentValidator"] = { proj: org.gradle.api.Project ->
    val projectDir = proj.projectDir
    val tag = "[suite-validator] ${proj.path}"

    require(projectDir.resolve("index.yml").isFile)    { "$tag index.yml missing in ${projectDir.path}" }
    require(projectDir.resolve("package.json").isFile) { "$tag package.json missing in ${projectDir.path}" }

    // index.yml schema
    val indexDoc = SchemaPrimitives.parseYaml(projectDir.resolve("index.yml"))
    SchemaPrimitives.requireUuid(indexDoc["id"], "index.yml id")
    SchemaPrimitives.requireNonBlankString(indexDoc["code"], "index.yml code")
    SchemaPrimitives.requireNonBlankString(indexDoc["name"], "index.yml name")
    // status: VspStatusEnum from @zerobias-com/platform-core core.yml
    SchemaPrimitives.requireEnum(
        indexDoc["status"], "index.yml status",
        setOf("draft", "active", "rejected", "deleted", "verified"),
    )
    SchemaPrimitives.requireUuid(indexDoc["vendorId"], "index.yml vendorId")
    SchemaPrimitives.requireNonBlankString(indexDoc["vendorCode"], "index.yml vendorCode")

    // description / url / logo are optional in the dataloader; only validate
    // format when present.
    indexDoc["description"]?.let {
        SchemaPrimitives.requireNonBlankString(it, "index.yml description")
    }
    indexDoc["url"]?.let { requireUrlFormat(it, "index.yml url", tag) }
    indexDoc["logo"]?.let { requireUrlFormat(it, "index.yml logo", tag) }
    indexDoc["aliases"]?.let { SchemaPrimitives.requireStringList(it, "index.yml aliases") }
    // tags items must be UUIDs (dataloader maps each through new UUID(tag)).
    indexDoc["tags"]?.let { tagsValue ->
        require(tagsValue is List<*>) { "$tag index.yml tags must be a list" }
        tagsValue.forEachIndexed { i, item ->
            SchemaPrimitives.requireUuid(item, "index.yml tags[$i]")
        }
    }

    val code = indexDoc["code"] as String
    val vendorCode = indexDoc["vendorCode"] as String
    SchemaPrimitives.requireCodeMatchesDir(code, projectDir.name, "index.yml code")
    require(projectDir.parentFile.name == vendorCode) {
        "$tag index.yml vendorCode='$vendorCode' must match parent directory '${projectDir.parentFile.name}'"
    }
    // Mirrors the dataloader's SuiteFileHandler code regex.
    require(Regex("^[\\d_a-z]+\$").matches(code)) {
        "$tag code='$code' must match ^[\\d_a-z]+\$ (lowercase alphanumeric with underscores) — see com/platform/dataloader SuiteFileHandler"
    }
    require(Regex("^[\\d_a-z]+\$").matches(vendorCode)) {
        "$tag vendorCode='$vendorCode' must match ^[\\d_a-z]+\$ — see SuiteFileHandler"
    }

    // package.json schema — npm name + zerobias block + parent linkage.
    val pkgDoc = SchemaPrimitives.parseJson(projectDir.resolve("package.json"))
    val expectedName = "@zerobias-org/suite-${vendorCode.replace('.', '-')}-${code.replace('.', '-')}"
    require(pkgDoc["name"] == expectedName) {
        "$tag package.json name is '${pkgDoc["name"]}' but expected '$expectedName' (derived from vendorCode=$vendorCode, code=$code)"
    }

    val artifact = SchemaPrimitives.getPath(pkgDoc, "zerobias.import-artifact")
        ?: SchemaPrimitives.getPath(pkgDoc, "auditmation.import-artifact")
    require(artifact == "suite") {
        "$tag expected zerobias.import-artifact='suite', got '$artifact'"
    }
    val pkgField = SchemaPrimitives.getPath(pkgDoc, "zerobias.package")
        ?: SchemaPrimitives.getPath(pkgDoc, "auditmation.package")
    val expectedPackage = "$vendorCode.$code"
    require(pkgField == expectedPackage) {
        "$tag zerobias.package='$pkgField' must equal '$expectedPackage' (vendorCode.code) — SuiteFileHandler enforces this"
    }
    val dataloaderVersion = SchemaPrimitives.getPath(pkgDoc, "zerobias.dataloader-version")
        ?: SchemaPrimitives.getPath(pkgDoc, "auditmation.dataloader-version")
    SchemaPrimitives.requireNonBlankString(dataloaderVersion, "zerobias.dataloader-version")

    proj.logger.lifecycle("$tag: vendorCode=$vendorCode code=$code")
}

val projectPaths by tasks.registering {
    group = "info"
    description = "Output project-to-directory mappings for tooling (used by zbb CLI)"
    doLast {
        subprojects.filter { it.buildFile.exists() }.forEach { p ->
            println("${p.path}=${p.projectDir.relativeTo(rootDir)}")
        }
    }
}

val changedModules by tasks.registering {
    group = "info"
    description = "List suites changed since last version tag"
    doLast {
        val lastTag = try {
            providers.exec {
                commandLine("git", "describe", "--tags", "--abbrev=0")
            }.standardOutput.asText.get().trim()
        } catch (e: Exception) {
            logger.warn("No version tags found -- listing all suites as changed")
            null
        }

        val diffArgs = if (lastTag != null) {
            listOf("git", "diff", "--name-only", lastTag, "HEAD")
        } else {
            listOf("git", "ls-files")
        }

        val result = providers.exec {
            commandLine(diffArgs)
        }.standardOutput.asText.get()

        val changed = result.lines()
            .filter { it.startsWith("package/") }
            .map { it.split("/").drop(1).take(2).joinToString("/") }
            .distinct()
            .filter { it.isNotEmpty() && it.contains("/") }

        changed.forEach { println(it) }
    }
}
