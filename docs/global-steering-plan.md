# Global Steering Implementation Plan for Goose

## Status (2026-10-24)

Partly built. The Goose + MCP sync (commit `f5bcdd0`) already delivers the core
of Phases 1-3: one repo source for steering and MCP, `.goosehints` relative
`@`-includes, the three steering files symlinked into `~/.config/goose`, and
`bootstrap.sh` `step_mcp` generating each client's config from
`agents/mcp/servers.json`. See `docs/agent-skills-sync-design.md` for the
shipped design. This file is the forward roadmap; the later phases (CI/CD for
config, encryption of private steering, formal testing) are not built.

## Overview
Implement a global steering system for Goose that allows centralized management and distribution of steering rules and configurations across multiple Goose instances, following the patterns established in the agent-skills-sync-design.md document.

## Architecture Goals

1. **Single Source of Truth**: All Goose instances reference a common repository for steering configurations
2. **Consistent Distribution**: Automated mechanisms to synchronize configurations across all instances
3. **Flexible Consumption**: Different methods to consume global steering based on agent type and needs
4. **Security and Access Control**: Manage both public and private steering configurations appropriately

## Implementation Steps

### Phase 1: Infrastructure Setup

#### 1.1 Create Central Configuration Repository
- Establish a dedicated Git repository for global steering configurations
- Define structure for organizing steering rules and policies
- Set up version control best practices for configuration management

#### 1.2 Define Configuration Structure
```
/global-steering/
├── rules/
│   ├── engineering-style.md
│   ├── interaction-preferences.md  
│   └── interaction-voice.md
├── skills/
│   ├── caveman/
│   ├── asd-ste100/
│   └── simple-english/
└── hooks/
    └── session-start/
```

### Phase 2: Distribution Mechanisms

#### 2.1 Bootstrap System Enhancement
- Extend existing bootstrap scripts to handle global steering configurations
- Implement logic to detect and deploy global steering configurations
- Add flags for enabling/disabling global steering distribution

#### 2.2 Symbolic Linking Strategy  
- Use symbolic links for skills (following pattern from document)
- Use direct copies or symlinks for steering rules based on agent needs
- Ensure proper handling of private steering configurations

#### 2.3 Multi-Agent Compatibility
- Kiro-specific steering rules (copied)
- Cline-specific steering rules (linked)
- Generic global steering rules (shared)

### Phase 3: Implementation Details

#### 3.1 Configuration Management
- Create standardized format for steering rules
- Implement validation for rule syntax and structure
- Design error handling when rules can't be loaded

#### 3.2 Deployment Automation
- Enhance bootstrap.sh to include global steering
- Create deployment scripts for different environments
- Set up CI/CD pipeline for configuration updates

#### 3.3 Security Implementation
- Separate public from private steering configurations 
- Implement proper access controls
- Create encryption for sensitive configuration data

### Phase 4: Testing and Validation

#### 4.1 Unit Testing
- Test individual steering rule loading
- Verify symbolic link creation and functionality
- Validate configuration parsing logic

#### 4.2 Integration Testing
- End-to-end testing of bootstrap processes
- Cross-agent consistency checking
- Rollback procedure verification

#### 4.3 Performance Testing
- Measure load times for global steering configurations
- Monitor memory usage impact
- Test scaling to multiple Goose instances

### Phase 5: Documentation and Maintenance

#### 5.1 User Documentation
- Guide for setting up global steering
- Best practices for configuration management
- Troubleshooting common issues

#### 5.2 Maintenance Procedures
- Regular updates and synchronization processes
- Backup and recovery strategies
- Monitoring and alerting systems

## Key Patterns from Existing System

### Copy vs Symlink Strategy
- **Skills**: Use symbolic links (verified for Kiro)
- **Steering Rules**: Copy for Kiro, link for Cline
- **Private Steering**: Separate repositories with specific handling

### Bootstrap Process
- `bootstrap.sh` command enhancements
- DRY_RUN capability for testing
- Skill restoration procedures

## Risk Mitigation

1. **Configuration Drift**: Implement automated checks for inconsistencies
2. **Deployment Failures**: Rollback mechanism and validation tests
3. **Performance Impact**: Optimize loading and caching of global configs
4. **Security Vulnerabilities**: Role-based access controls and encryption

## Timeline Estimate
- Phase 1: 2 weeks
- Phase 2: 3 weeks  
- Phase 3: 4 weeks
- Phase 4: 2 weeks
- Phase 5: 1 week
- Total: ~12 weeks

## Success Metrics
- Consistent global configuration across all Goose instances
- Minimal performance impact on agent operations
- Successful rollback capability in case of issues
- Clear documentation and user adoption