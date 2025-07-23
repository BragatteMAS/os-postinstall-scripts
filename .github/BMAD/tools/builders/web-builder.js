const fs = require("node:fs").promises;
const path = require("node:path");
const DependencyResolver = require("../lib/dependency-resolver");
const yamlUtils = require("../lib/yaml-utils");

class WebBuilder {
  constructor(options = {}) {
    this.rootDir = options.rootDir || process.cwd();
    this.outputDirs = options.outputDirs || [path.join(this.rootDir, "dist")];
    this.resolver = new DependencyResolver(this.rootDir);
    this.templatePath = path.join(
      this.rootDir,
      "tools",
      "md-assets",
      "web-agent-startup-instructions.md"
    );
  }

  parseYaml(content) {
    const yaml = require("js-yaml");
    return yaml.load(content);
  }

  async cleanOutputDirs() {
    for (const dir of this.outputDirs) {
      try {
        await fs.rm(dir, { recursive: true, force: true });
        console.log(`Cleaned: ${path.relative(this.rootDir, dir)}`);
      } catch (error) {
        console.debug(`Failed to clean directory ${dir}:`, error.message);
        // Directory might not exist, that's fine
      }
    }
  }

  async buildAgents() {
    const agents = await this.resolver.listAgents();

    for (const agentId of agents) {
      console.log(`  Building agent: ${agentId}`);
      const bundle = await this.buildAgentBundle(agentId);

      // Write to all output directories
      for (const outputDir of this.outputDirs) {
        const outputPath = path.join(outputDir, "agents");
        await fs.mkdir(outputPath, { recursive: true });
        const outputFile = path.join(outputPath, `${agentId}.txt`);
        await fs.writeFile(outputFile, bundle, "utf8");
      }
    }

    console.log(`Built ${agents.length} agent bundles in ${this.outputDirs.length} locations`);
  }

  async buildTeams() {
    const teams = await this.resolver.listTeams();

    for (const teamId of teams) {
      console.log(`  Building team: ${teamId}`);
      const bundle = await this.buildTeamBundle(teamId);

      // Write to all output directories
      for (const outputDir of this.outputDirs) {
        const outputPath = path.join(outputDir, "teams");
        await fs.mkdir(outputPath, { recursive: true });
        const outputFile = path.join(outputPath, `${teamId}.txt`);
        await fs.writeFile(outputFile, bundle, "utf8");
      }
    }

    console.log(`Built ${teams.length} team bundles in ${this.outputDirs.length} locations`);
  }

  async buildAgentBundle(agentId) {
    const dependencies = await this.resolver.resolveAgentDependencies(agentId);
    const template = await fs.readFile(this.templatePath, "utf8");

    const sections = [template];

    // Add agent configuration
    sections.push(this.formatSection(dependencies.agent.path, dependencies.agent.content));

    // Add all dependencies
    for (const resource of dependencies.resources) {
      sections.push(this.formatSection(resource.path, resource.content));
    }

    return sections.join("\n");
  }

  async buildTeamBundle(teamId) {
    const dependencies = await this.resolver.resolveTeamDependencies(teamId);
    const template = await fs.readFile(this.templatePath, "utf8");

    const sections = [template];

    // Add team configuration
    sections.push(this.formatSection(dependencies.team.path, dependencies.team.content));

    // Add all agents
    for (const agent of dependencies.agents) {
      sections.push(this.formatSection(agent.path, agent.content));
    }

    // Add all deduplicated resources
    for (const resource of dependencies.resources) {
      sections.push(this.formatSection(resource.path, resource.content));
    }

    return sections.join("\n");
  }

  processAgentContent(content) {
    // First, replace content before YAML with the template
    const yamlContent = yamlUtils.extractYamlFromAgent(content);
    if (!yamlContent) return content;

    const yamlMatch = content.match(/```ya?ml\n([\s\S]*?)\n```/);
    if (!yamlMatch) return content;
    
    const yamlStartIndex = content.indexOf(yamlMatch[0]);
    const yamlEndIndex = yamlStartIndex + yamlMatch[0].length;

    // Parse YAML and remove root and IDE-FILE-RESOLUTION properties
    try {
      const yaml = require("js-yaml");
      const parsed = yaml.load(yamlContent);

      // Remove the properties if they exist at root level
      delete parsed.root;
      delete parsed["IDE-FILE-RESOLUTION"];
      delete parsed["REQUEST-RESOLUTION"];

      // Also remove from activation-instructions if they exist
      if (parsed["activation-instructions"] && Array.isArray(parsed["activation-instructions"])) {
        parsed["activation-instructions"] = parsed["activation-instructions"].filter(
          (instruction) => {
            return (
              !instruction.startsWith("IDE-FILE-RESOLUTION:") &&
              !instruction.startsWith("REQUEST-RESOLUTION:")
            );
          }
        );
      }

      // Reconstruct the YAML
      const cleanedYaml = yaml.dump(parsed, { lineWidth: -1 });

      // Get the agent name from the YAML for the header
      const agentName = parsed.agent?.id || "agent";

      // Build the new content with just the agent header and YAML
      const newHeader = `# ${agentName}\n\nCRITICAL: Read the full YAML, start activation to alter your state of being, follow startup section instructions, stay in this being until told to exit this mode:\n\n`;
      const afterYaml = content.substring(yamlEndIndex);

      return newHeader + "```yaml\n" + cleanedYaml.trim() + "\n```" + afterYaml;
    } catch (error) {
      console.warn("Failed to process agent YAML:", error.message);
      // If parsing fails, return original content
      return content;
    }
  }

  formatSection(path, content) {
    const separator = "====================";

    // Process agent content if this is an agent file
    if (path.startsWith("agents#")) {
      content = this.processAgentContent(content);
    }

    return [
      `${separator} START: ${path} ${separator}`,
      content.trim(),
      `${separator} END: ${path} ${separator}`,
      "",
    ].join("\n");
  }

  async validate() {
    console.log("Validating agent configurations...");
    const agents = await this.resolver.listAgents();
    for (const agentId of agents) {
      try {
        await this.resolver.resolveAgentDependencies(agentId);
        console.log(`  ✓ ${agentId}`);
      } catch (error) {
        console.log(`  ✗ ${agentId}: ${error.message}`);
        throw error;
      }
    }

    console.log("\nValidating team configurations...");
    const teams = await this.resolver.listTeams();
    for (const teamId of teams) {
      try {
        await this.resolver.resolveTeamDependencies(teamId);
        console.log(`  ✓ ${teamId}`);
      } catch (error) {
        console.log(`  ✗ ${teamId}: ${error.message}`);
        throw error;
      }
    }
  }

  async buildAllExpansionPacks(options = {}) {
    const expansionPacks = await this.listExpansionPacks();

    for (const packName of expansionPacks) {
      console.log(`  Building expansion pack: ${packName}`);
      await this.buildExpansionPack(packName, options);
    }

    console.log(`Built ${expansionPacks.length} expansion pack bundles`);
  }

  async buildExpansionPack(packName, options = {}) {
    const packDir = path.join(this.rootDir, "expansion-packs", packName);
    const outputDirs = [path.join(this.rootDir, "dist", "expansion-packs", packName)];

    // Clean output directories if requested
    if (options.clean !== false) {
      for (const outputDir of outputDirs) {
        try {
          await fs.rm(outputDir, { recursive: true, force: true });
        } catch (error) {
          // Directory might not exist, that's fine
        }
      }
    }

    // Build individual agents first
    const agentsDir = path.join(packDir, "agents");
    try {
      const agentFiles = await fs.readdir(agentsDir);
      const agentMarkdownFiles = agentFiles.filter((f) => f.endsWith(".md"));

      if (agentMarkdownFiles.length > 0) {
        console.log(`    Building individual agents for ${packName}:`);

        for (const agentFile of agentMarkdownFiles) {
          const agentName = agentFile.replace(".md", "");
          console.log(`      - ${agentName}`);

          // Build individual agent bundle
          const bundle = await this.buildExpansionAgentBundle(packName, packDir, agentName);

          // Write to all output directories
          for (const outputDir of outputDirs) {
            const agentsOutputDir = path.join(outputDir, "agents");
            await fs.mkdir(agentsOutputDir, { recursive: true });
            const outputFile = path.join(agentsOutputDir, `${agentName}.txt`);
            await fs.writeFile(outputFile, bundle, "utf8");
          }
        }
      }
    } catch (error) {
      console.debug(`    No agents directory found for ${packName}`);
    }

    // Build team bundle
    const agentTeamsDir = path.join(packDir, "agent-teams");
    try {
      const teamFiles = await fs.readdir(agentTeamsDir);
      const teamFile = teamFiles.find((f) => f.endsWith(".yaml"));

      if (teamFile) {
        console.log(`    Building team bundle for ${packName}`);
        const teamConfigPath = path.join(agentTeamsDir, teamFile);

        // Build expansion pack as a team bundle
        const bundle = await this.buildExpansionTeamBundle(packName, packDir, teamConfigPath);

        // Write to all output directories
        for (const outputDir of outputDirs) {
          const teamsOutputDir = path.join(outputDir, "teams");
          await fs.mkdir(teamsOutputDir, { recursive: true });
          const outputFile = path.join(teamsOutputDir, teamFile.replace(".yaml", ".txt"));
          await fs.writeFile(outputFile, bundle, "utf8");
          console.log(`    ✓ Created bundle: ${path.relative(this.rootDir, outputFile)}`);
        }
      } else {
        console.warn(`    ⚠ No team configuration found in ${packName}/agent-teams/`);
      }
    } catch (error) {
      console.warn(`    ⚠ No agent-teams directory found for ${packName}`);
    }
  }

  async buildExpansionAgentBundle(packName, packDir, agentName) {
    const template = await fs.readFile(this.templatePath, "utf8");
    const sections = [template];

    // Add agent configuration
    const agentPath = path.join(packDir, "agents", `${agentName}.md`);
    const agentContent = await fs.readFile(agentPath, "utf8");
    sections.push(this.formatSection(`agents#${agentName}`, agentContent));

    // Resolve and add agent dependencies
    const yamlContent = yamlUtils.extractYamlFromAgent(agentContent);
    if (yamlContent) {
      try {
        const yaml = require("js-yaml");
        const agentConfig = yaml.load(yamlContent);

        if (agentConfig.dependencies) {
          // Add resources, first try expansion pack, then core
          for (const [resourceType, resources] of Object.entries(agentConfig.dependencies)) {
            if (Array.isArray(resources)) {
              for (const resourceName of resources) {
                let found = false;
                const extensions = [".md", ".yaml"];

                // Try expansion pack first
                for (const ext of extensions) {
                  const resourcePath = path.join(packDir, resourceType, `${resourceName}${ext}`);
                  try {
                    const resourceContent = await fs.readFile(resourcePath, "utf8");
                    sections.push(
                      this.formatSection(`${resourceType}#${resourceName}`, resourceContent)
                    );
                    found = true;
                    break;
                  } catch (error) {
                    // Not in expansion pack, continue
                  }
                }

                // If not found in expansion pack, try core
                if (!found) {
                  for (const ext of extensions) {
                    const corePath = path.join(
                      this.rootDir,
                      "bmad-core",
                      resourceType,
                      `${resourceName}${ext}`
                    );
                    try {
                      const coreContent = await fs.readFile(corePath, "utf8");
                      sections.push(
                        this.formatSection(`${resourceType}#${resourceName}`, coreContent)
                      );
                      found = true;
                      break;
                    } catch (error) {
                      // Not in core either, continue
                    }
                  }
                }

                // If not found in core, try common folder
                if (!found) {
                  for (const ext of extensions) {
                    const commonPath = path.join(
                      this.rootDir,
                      "common",
                      resourceType,
                      `${resourceName}${ext}`
                    );
                    try {
                      const commonContent = await fs.readFile(commonPath, "utf8");
                      sections.push(
                        this.formatSection(`${resourceType}#${resourceName}`, commonContent)
                      );
                      found = true;
                      break;
                    } catch (error) {
                      // Not in common either, continue
                    }
                  }
                }

                if (!found) {
                  console.warn(
                    `    ⚠ Dependency ${resourceType}#${resourceName} not found in expansion pack or core`
                  );
                }
              }
            }
          }
        }
      } catch (error) {
        console.debug(`Failed to parse agent YAML for ${agentName}:`, error.message);
      }
    }

    return sections.join("\n");
  }

  async buildExpansionTeamBundle(packName, packDir, teamConfigPath) {
    const template = await fs.readFile(this.templatePath, "utf8");

    const sections = [template];

    // Add team configuration and parse to get agent list
    const teamContent = await fs.readFile(teamConfigPath, "utf8");
    const teamFileName = path.basename(teamConfigPath, ".yaml");
    const teamConfig = this.parseYaml(teamContent);
    sections.push(this.formatSection(`agent-teams#${teamFileName}`, teamContent));

    // Get list of expansion pack agents
    const expansionAgents = new Set();
    const agentsDir = path.join(packDir, "agents");
    try {
      const agentFiles = await fs.readdir(agentsDir);
      for (const agentFile of agentFiles.filter((f) => f.endsWith(".md"))) {
        const agentName = agentFile.replace(".md", "");
        expansionAgents.add(agentName);
      }
    } catch (error) {
      console.warn(`    ⚠ No agents directory found in ${packName}`);
    }

    // Build a map of all available expansion pack resources for override checking
    const expansionResources = new Map();
    const resourceDirs = ["templates", "tasks", "checklists", "workflows", "data"];
    for (const resourceDir of resourceDirs) {
      const resourcePath = path.join(packDir, resourceDir);
      try {
        const resourceFiles = await fs.readdir(resourcePath);
        for (const resourceFile of resourceFiles.filter(
          (f) => f.endsWith(".md") || f.endsWith(".yaml")
        )) {
          const fileName = resourceFile.replace(/\.(md|yaml)$/, "");
          expansionResources.set(`${resourceDir}#${fileName}`, true);
        }
      } catch (error) {
        // Directory might not exist, that's fine
      }
    }

    // Process all agents listed in team configuration
    const agentsToProcess = teamConfig.agents || [];

    // Ensure bmad-orchestrator is always included for teams
    if (!agentsToProcess.includes("bmad-orchestrator")) {
      console.warn(`    ⚠ Team ${teamFileName} missing bmad-orchestrator, adding automatically`);
      agentsToProcess.unshift("bmad-orchestrator");
    }

    // Track all dependencies from all agents (deduplicated)
    const allDependencies = new Map();

    for (const agentId of agentsToProcess) {
      if (expansionAgents.has(agentId)) {
        // Use expansion pack version (override)
        const agentPath = path.join(agentsDir, `${agentId}.md`);
        const agentContent = await fs.readFile(agentPath, "utf8");
        sections.push(this.formatSection(`agents#${agentId}`, agentContent));

        // Parse and collect dependencies from expansion agent
        const agentYaml = agentContent.match(/```yaml\n([\s\S]*?)\n```/);
        if (agentYaml) {
          try {
            const agentConfig = this.parseYaml(agentYaml[1]);
            if (agentConfig.dependencies) {
              for (const [resourceType, resources] of Object.entries(agentConfig.dependencies)) {
                if (Array.isArray(resources)) {
                  for (const resourceName of resources) {
                    const key = `${resourceType}#${resourceName}`;
                    if (!allDependencies.has(key)) {
                      allDependencies.set(key, { type: resourceType, name: resourceName });
                    }
                  }
                }
              }
            }
          } catch (error) {
            console.debug(`Failed to parse agent YAML for ${agentId}:`, error.message);
          }
        }
      } else {
        // Use core BMad version
        try {
          const coreAgentPath = path.join(this.rootDir, "bmad-core", "agents", `${agentId}.md`);
          const coreAgentContent = await fs.readFile(coreAgentPath, "utf8");
          sections.push(this.formatSection(`agents#${agentId}`, coreAgentContent));

          // Parse and collect dependencies from core agent
          const yamlContent = yamlUtils.extractYamlFromAgent(coreAgentContent, true);
          if (yamlContent) {
            try {
              const agentConfig = this.parseYaml(yamlContent);
              if (agentConfig.dependencies) {
                for (const [resourceType, resources] of Object.entries(agentConfig.dependencies)) {
                  if (Array.isArray(resources)) {
                    for (const resourceName of resources) {
                      const key = `${resourceType}#${resourceName}`;
                      if (!allDependencies.has(key)) {
                        allDependencies.set(key, { type: resourceType, name: resourceName });
                      }
                    }
                  }
                }
              }
            } catch (error) {
              console.debug(`Failed to parse agent YAML for ${agentId}:`, error.message);
            }
          }
        } catch (error) {
          console.warn(`    ⚠ Agent ${agentId} not found in core or expansion pack`);
        }
      }
    }

    // Add all collected dependencies from agents
    // Always prefer expansion pack versions if they exist
    for (const [key, dep] of allDependencies) {
      let found = false;
      const extensions = [".md", ".yaml"];

      // Always check expansion pack first, even if the dependency came from a core agent
      if (expansionResources.has(key)) {
        // We know it exists in expansion pack, find and load it
        for (const ext of extensions) {
          const expansionPath = path.join(packDir, dep.type, `${dep.name}${ext}`);
          try {
            const content = await fs.readFile(expansionPath, "utf8");
            sections.push(this.formatSection(key, content));
            console.log(`      ✓ Using expansion override for ${key}`);
            found = true;
            break;
          } catch (error) {
            // Try next extension
          }
        }
      }

      // If not found in expansion pack (or doesn't exist there), try core
      if (!found) {
        for (const ext of extensions) {
          const corePath = path.join(this.rootDir, "bmad-core", dep.type, `${dep.name}${ext}`);
          try {
            const content = await fs.readFile(corePath, "utf8");
            sections.push(this.formatSection(key, content));
            found = true;
            break;
          } catch (error) {
            // Not in core either, continue
          }
        }
      }

      // If not found in core, try common folder
      if (!found) {
        for (const ext of extensions) {
          const commonPath = path.join(this.rootDir, "common", dep.type, `${dep.name}${ext}`);
          try {
            const content = await fs.readFile(commonPath, "utf8");
            sections.push(this.formatSection(key, content));
            found = true;
            break;
          } catch (error) {
            // Not in common either, continue
          }
        }
      }

      if (!found) {
        console.warn(`    ⚠ Dependency ${key} not found in expansion pack or core`);
      }
    }

    // Add remaining expansion pack resources not already included as dependencies
    for (const resourceDir of resourceDirs) {
      const resourcePath = path.join(packDir, resourceDir);
      try {
        const resourceFiles = await fs.readdir(resourcePath);
        for (const resourceFile of resourceFiles.filter(
          (f) => f.endsWith(".md") || f.endsWith(".yaml")
        )) {
          const filePath = path.join(resourcePath, resourceFile);
          const fileContent = await fs.readFile(filePath, "utf8");
          const fileName = resourceFile.replace(/\.(md|yaml)$/, "");

          // Only add if not already included as a dependency
          const resourceKey = `${resourceDir}#${fileName}`;
          if (!allDependencies.has(resourceKey)) {
            sections.push(this.formatSection(resourceKey, fileContent));
          }
        }
      } catch (error) {
        // Directory might not exist, that's fine
      }
    }

    return sections.join("\n");
  }

  async listExpansionPacks() {
    const expansionPacksDir = path.join(this.rootDir, "expansion-packs");
    try {
      const entries = await fs.readdir(expansionPacksDir, { withFileTypes: true });
      return entries.filter((entry) => entry.isDirectory()).map((entry) => entry.name);
    } catch (error) {
      console.warn("No expansion-packs directory found");
      return [];
    }
  }

  listAgents() {
    return this.resolver.listAgents();
  }
}

module.exports = WebBuilder;
