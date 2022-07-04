case=use_case/withDA.sh
case=use_case/withDA_LM.sh

defalut:
	make build submit

all: build submit

edit:
	vim $(case)
build:
	./setup_experiment.sh $(case)
submit:
	./submit_experiment.sh $(case)
