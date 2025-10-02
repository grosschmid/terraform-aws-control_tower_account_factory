#!/bin/bash
# AFT Repository Cleanup Script for Compliance
# Removes non-essential files while preserving required legal and functional files

echo "🧹 Cleaning AFT repository for compliance..."

# Remove non-essential files/folders
rm -rf .github/ 2>/dev/null || true
rm -f .coveragerc 2>/dev/null || true
rm -rf docs/ 2>/dev/null || true
rm -rf examples/ 2>/dev/null || true
rm -f CHANGELOG.md 2>/dev/null || true
rm -f CODEOWNERS 2>/dev/null || true
rm -f CONTRIBUTING.md 2>/dev/null || true
rm -f CODE_OF_CONDUCT.md 2>/dev/null || true
rm -f SECURITY.md 2>/dev/null || true
rm -f .pre-commit-config.yaml 2>/dev/null || true
rm -f .terraform-docs.yml 2>/dev/null || true
rm -f Makefile 2>/dev/null || true
rm -rf scripts/ 2>/dev/null || true

echo "✅ Cleanup completed"
echo ""
echo "Preserved essential files:"
echo "📄 LICENSE - Apache 2.0 license (REQUIRED)"
echo "📄 NOTICE - Attribution notices (REQUIRED)"  
echo "📄 Core module files (main.tf, variables.tf, etc.)"
echo "📁 modules/ - AFT sub-modules"
echo "📁 sources/ - Template repositories" 
echo "📁 src/ - Lambda function source code"
echo "📄 VERSION, PYTHON_VERSION - Version specifications"
