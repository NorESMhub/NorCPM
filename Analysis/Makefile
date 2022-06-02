## Some operations can be use in the directory
## Just for convenice

## which setting file is using
caseset='use_cases/template_betzy.in'
analysis='setting/analysis_example.sh'

## show what can be done
default: 
	@echo 'Start from 0:'
	@echo '  Check caseset and analysis variable in Makefile:'
	@echo '  Check following 2 setting are point to same casedir:'
	@echo '    $(caseset)'
	@echo '    $(analysis)'
	@echo '  Then:'
	@echo '    make check  ## check the restart files set in $(caseset)'
	@echo '    make build  ## to create case and compile'
	@echo '    make checkana   ## check the data file used to analysis run'
	@echo '    make submitana  ## submit the analysis run'
	@echo '  It also can be combined:'
	@echo '    make check build checkana submitana ## do everything if no error'

## check restart file are presented
check:
	./check_case.sh $(caseset)

## build 1st and other members
build: build_template build_ensemble
build_template:
	./create_template.sh $(caseset)
build_ensemble:
	./create_ensemble.sh $(caseset)
## submit job without DA
submit:
	./submit_ensemble.sh $(caseset)

## edit setting file
edit:
	vim $(caseset)

## for analysis (data assimilation) run
checkana:
	./check_analysis_data.sh $(analysis)
editana:
	vim $(analysis)
submitana:
	./submit_analysis.sh $(analysis)
