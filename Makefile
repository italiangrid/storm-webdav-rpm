name=storm-webdav
tag=master

# the voms-clients repo on GitHub
git=https://github.com/italiangrid/storm-webdav.git

# needed dirs
source_dir=sources
rpmbuild_dir=$(shell pwd)/rpmbuild

# spec file and it src
spec_src=$(name).spec.in
spec=$(name).spec
dist=.el6

# determine the pom version and the rpm version
pom_version=$(shell grep "<version>" $(source_dir)/$(name)/pom.xml | head -1 | sed -e 's/<version>//g' -e 's/<\/version>//g' -e "s/[ \t]*//g")
#rpm_version=$(shell grep "base_version" $(spec) | head -1 | sed -e 's/%global base_version//g' -e 's/[ \t]*//g')

# settings file for mvn
mirror_conf_url=https://raw.githubusercontent.com/italiangrid/build-settings/master/maven/cnaf-mirror-settings.xml
mirror_conf_name=mirror-settings.xml

# maven build options
mvn_settings=-s $(mirror_conf_name)

.PHONY: clean rpm

all: rpm

print-info:
	@echo
	@echo
	@echo "Packaging $(name) fetched from $(git) for tag $(tag)."
	@echo "Maven settings: $(mvn_settings)"
	@echo "Jar names: $(jar_names)"
	@echo

prepare-sources: sanity-checks clean
	mkdir -p $(source_dir)/$(name)
	git clone $(git) $(source_dir)/$(name)
	cd $(source_dir)/$(name) && git checkout $(tag) && git archive --format=tar --prefix=$(name)/ $(tag) > $(name).tar
	# Maven mirror settings 
	wget --no-check-certificate $(mirror_conf_url) -O $(source_dir)/$(name)/$(mirror_conf_name)
	cd $(source_dir) && tar -r -f $(name)/$(name).tar $(name)/$(mirror_conf_name) && gzip $(name)/$(name).tar
	cp $(source_dir)/$(name)/$(name).tar.gz $(source_dir)/$(name).tar.gz

prepare-spec: prepare-sources
	sed -e 's#@@MVN_SETTINGS@@#$(mvn_settings)#g' \
    	-e 's#@@POM_VERSION@@#$(pom_version)#g' \
	$(spec_src) > $(spec)

rpm: prepare-spec
	mkdir -p $(rpmbuild_dir)/BUILD \
		$(rpmbuild_dir)/RPMS \
		$(rpmbuild_dir)/SOURCES \
		$(rpmbuild_dir)/SPECS \
		$(rpmbuild_dir)/SRPMS
	echo $(rpm_version); exit  
	cp $(source_dir)/$(name).tar.gz $(rpmbuild_dir)/SOURCES
ifndef build_number
	rpmbuild --nodeps -v -ba $(spec) --define "_topdir $(rpmbuild_dir)" --define "dist $(dist)"
else
	rpmbuild --nodeps -v -ba $(spec) --define "_topdir $(rpmbuild_dir)" --define "dist $(dist)" --define "build_number $(build_number)"
endif

clean:
	rm -rf $(source_dir) $(rpmbuild_dir) $(spec)

sanity-checks:
ifndef tag
	$(error tag is undefined)
endif
