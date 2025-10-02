# AFT Fork Maintenance

This is a cleaned fork of AWS Control Tower Account Factory for Terraform (AFT).

## What's Different from Upstream

This fork removes non-essential files for compliance:
- Documentation folders (`docs/`, `examples/`)
- CI/CD configurations (`.github/`, `Makefile`)
- Development tools (`.pre-commit-config.yaml`, etc.)

**Preserved essentials:**
- ✅ All functional Terraform code
- ✅ Legal files (`LICENSE`, `NOTICE`)
- ✅ Template repositories (`sources/`)
- ✅ Lambda source code (`src/`)

## Maintenance Scripts

### `update-aft.sh`
Updates the fork with latest AWS changes:
```bash
./update-aft.sh
```

### `cleanup-aft.sh`
Re-applies cleanup (used by update script):
```bash
./cleanup-aft.sh
```

## Usage in Projects

Reference your specific tagged version:
```hcl
module "aft" {
  source = "github.com/<your-org>/terraform-aws-control_tower_account_factory?ref=v1.12.0-clean"
  
  # Your configuration...
}
```

## Updating Process

1. Run `./update-aft.sh`
2. Follow the prompts to select version
3. Review changes and create PR
4. Update downstream projects to new tag

## Support

For questions about this fork, contact the Platform Core team.
For AFT issues, see: https://github.com/aws-ia/terraform-aws-control_tower_account_factory/issues
