## Some operations can be use in the directory
## Just for convenice

## which setting file is using
caseset='use_cases/template_betzy.in'

## show what can be done
default: 
	@echo make build submit 

## check restart file are presented
check:
	./check_case.sh $(caseset)

## build 1st and other members
build: build_template build_ensemble
build_template:
	./create_template.sh $(caseset)
build_ensemble:
	./create_ensemble.sh $(caseset)

## submit job
submit:
	./submit_ensemble.sh $(caseset)

## edit setting file
edit:
	vim $(caseset)
