.DEFAULT_GOAL := help

.PHONY: help clean render serve
.PHONY: publish

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z_-]+:.*##/ {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Remove the rendered website
	rm -rf docs/

render: ## Render the website into docs/
	quarto render

serve: ## Serve the rendered website locally
	calepin serve docs/

publish: render ## Render, then push docs/ to the gh-pages branch
	quarto publish gh-pages --no-render --no-prompt --no-browser
