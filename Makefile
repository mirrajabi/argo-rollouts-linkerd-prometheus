create:
	./create-vm.sh

destroy:
	multipass delete rollouts-playground -p

simulate-success:
	multipass exec rollouts-playground -- bash -c "sudo /opt/init/simulate-successful-rollout.sh"

simulate-failure:
	multipass exec rollouts-playground -- bash -c "sudo /opt/init/simulate-failed-rollout.sh"
