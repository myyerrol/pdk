DIR ?= IP/STD_cell

COMP_DIR        := $(shell find $(DIR) -type d -name liberty)
COMP_DIR_PARENT := $(patsubst %/liberty, %, $(COMP_DIR))
COMP_BZ2_PATH   := $(addsuffix _liberty.tar.bz2, $(COMP_DIR_PARENT))

.PHONY: zip clean-old-bz2 test

$(COMP_BZ2_PATH): %_liberty.tar.bz2: %/liberty
	@echo "\nCompressing: $< -> $@"
	@tar -cjvf $@ -C $(dir $<) $(notdir $<)

test:
	@echo $(COMP_BZ2_PATH)

zip: clean-old-bz2 $(COMP_BZ2_PATH)
	@echo "\nAll liberty directories have been compressed!"

clean-old-bz2:
	@echo "Cleaning up all old archives..."
	@find $(DIR) -name *.tar.bz2 -exec rm -fv {} \; || true




EXTR_BZ2 := $(shell find $(DIR) -name liberty.tar.bz2)
EXTR_DIR := $(patsubst %.tar.bz2, %, $(EXTR_BZ2))

.PHONY: unzip clean-old-dir

%: %.tar.bz2
	@echo "\nExtracting: $< -> $@"
	@mkdir -p $@
	@tar -xjvf $< -C $(dir $@)
	@touch $@

unzip: clean-old-dir $(EXTR_DIR)
	@echo "\nAll liberty.tar.bz2 files have been extracted!"

clean-old-dir:
	@echo "Cleaning up all old directories..."
	@find $(DIR) -depth -type d -name liberty -exec rm -rfv {} \; || true

.PRECIOUS: % $(EXTR_DIR)





.PHONY: upload check-gh-release

# 默认版本号、标题和说明（可通过命令行覆盖）
VERSION ?= v1.1.0
TITLE ?= "Test Title"
NOTES ?= "Test Notes"
RELEASE_FILE ?= liberty.tar.bz2

# 检查 gh release 状态
check-gh-release:
	@if ! gh auth status >/dev/null 2>&1; then \
		echo "Error: GitHub release status check failed. Are you in a repo with releases?"; \
		exit 1; \
	fi

# 上传发布包
upload: check-gh-release
	@echo "Creating GitHub release $(VERSION)..."
	gh release create $(VERSION) $(COMP_BZ2_PATH) --title $(TITLE) --notes $(NOTES)
	@echo "Release $(VERSION) uploaded successfully!"