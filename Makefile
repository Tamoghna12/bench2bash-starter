# Makefile for bench2bash-starter
# Reproducible bioinformatics pipeline automation

# Configuration
ENV_NAME = bench2bash-research
CONFIG_FILE = config/config.yaml
SNAKEFILE = workflows/snakemake/Snakefile

# Default target
.DEFAULT_GOAL := help

## Setup: Initialize environment and dependencies
.PHONY: setup
setup:
	@echo "🔧 Setting up bench2bash research environment..."
	@if conda env list | grep -q "$(ENV_NAME)"; then \
		echo "⚠️  Environment '$(ENV_NAME)' already exists. Use 'make update-env' to update."; \
	else \
		conda env create -f environment.yml; \
		echo "✅ Environment '$(ENV_NAME)' created successfully!"; \
	fi
	@echo "🚀 To activate: conda activate $(ENV_NAME)"

## Update environment from yml file
.PHONY: update-env
update-env:
	@echo "⬆️  Updating conda environment..."
	conda env update -f environment.yml --prune
	@echo "✅ Environment updated!"

## Run: Execute main pipeline with Snakemake
.PHONY: run
run:
	@echo "🏃 Running bench2bash pipeline..."
	@if [ ! -f "$(CONFIG_FILE)" ]; then \
		echo "⚠️  Config file not found. Creating from template..."; \
		mkdir -p config; \
		cp config/config.template.yaml config/config.yaml; \
	fi
	snakemake --configfile $(CONFIG_FILE) --cores 4 --use-conda

## Run with specific number of cores
.PHONY: run-parallel
run-parallel:
	@echo "🚀 Running pipeline with maximum cores..."
	snakemake --configfile $(CONFIG_FILE) --cores all --use-conda

## Dry run: Show what would be executed
.PHONY: dry-run
dry-run:
	@echo "🔍 Dry run - showing pipeline steps..."
	snakemake --configfile $(CONFIG_FILE) --dry-run --quiet

## DAG: Generate workflow diagram  
.PHONY: dag
dag:
	@echo "📊 Generating workflow diagram..."
	snakemake --configfile $(CONFIG_FILE) --dag | dot -Tpng > workflow_dag.png
	@echo "✅ Workflow diagram saved as workflow_dag.png"

## Test: Run validation tests
.PHONY: test
test:
	@echo "🧪 Running pipeline tests..."
	@if [ -d "tests" ]; then \
		python -m pytest tests/ -v; \
	else \
		echo "⚠️  No tests directory found. Creating basic test structure..."; \
		mkdir -p tests; \
		echo "# Add your tests here" > tests/test_pipeline.py; \
	fi

## Lint: Check code quality
.PHONY: lint
lint:
	@echo "🔍 Checking code quality..."
	@if command -v snakemake >/dev/null 2>&1; then \
		snakemake --lint; \
	fi
	@if command -v black >/dev/null 2>&1; then \
		black scripts/; \
	fi

## Clean: Remove temporary files and outputs
.PHONY: clean
clean:
	@echo "🧹 Cleaning temporary files..."
	rm -rf results/temp/
	rm -rf .snakemake/
	rm -rf logs/
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "✅ Cleanup complete!"

## Deep clean: Remove all outputs and logs
.PHONY: clean-all
clean-all: clean
	@echo "🗑️  Deep cleaning - removing all outputs..."
	@read -p "Are you sure? This will delete all results! (y/N): " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -rf results/; \
		mkdir -p results; \
		echo "✅ All outputs removed!"; \
	else \
		echo "❌ Aborted."; \
	fi

## Docs: Generate documentation
.PHONY: docs
docs:
	@echo "📚 Generating documentation..."
	@if [ -d "docs" ]; then \
		echo "✅ Documentation available in docs/ directory"; \
		ls docs/; \
	else \
		mkdir -p docs; \
		echo "# Project Documentation" > docs/README.md; \
		echo "✅ Created basic documentation structure"; \
	fi

## Docker build: Create container
.PHONY: docker-build
docker-build:
	@echo "🐳 Building Docker container..."
	@if [ -f "Dockerfile" ]; then \
		docker build -t bench2bash-starter:latest .; \
	else \
		echo "⚠️  Dockerfile not found. Creating basic Dockerfile..."; \
		echo "FROM continuumio/miniconda3" > Dockerfile; \
		echo "COPY environment.yml /tmp/" >> Dockerfile; \
		echo "RUN conda env create -f /tmp/environment.yml" >> Dockerfile; \
		echo "✅ Basic Dockerfile created. Customize and run again."; \
	fi

## Docker run: Execute pipeline in container
.PHONY: docker-run
docker-run:
	@echo "🐳 Running pipeline in Docker container..."
	docker run -v $(PWD):/workspace -w /workspace bench2bash-starter:latest make run

## Status: Check pipeline status
.PHONY: status
status:
	@echo "📊 Pipeline Status:"
	@echo "===================="
	@if [ -f "$(CONFIG_FILE)" ]; then \
		echo "✅ Config file: $(CONFIG_FILE)"; \
	else \
		echo "❌ Config file missing: $(CONFIG_FILE)"; \
	fi
	@if [ -d "results" ]; then \
		echo "📁 Results directory: $(shell du -sh results 2>/dev/null || echo 'empty')"; \
	else \
		echo "❌ Results directory missing"; \
	fi
	@if conda env list | grep -q "$(ENV_NAME)"; then \
		echo "✅ Conda environment: $(ENV_NAME)"; \
	else \
		echo "❌ Conda environment missing: $(ENV_NAME)"; \
	fi

## Help: Show available commands
.PHONY: help
help:
	@echo "🧬 bench2bash-starter Makefile"
	@echo "=============================="
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "🚀 Quick start: make setup && conda activate $(ENV_NAME) && make run"