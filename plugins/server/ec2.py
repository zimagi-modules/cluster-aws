from systems.plugins.index import BaseProvider


class Provider(BaseProvider('server', 'ec2')):

    def initialize_terraform(self, instance, created):
        if 'key_name' not in instance.config:
            key_name, private_key = self.create_aws_ec2_keypair(instance.subnet.network)
            instance.config['key_name'] = key_name
            instance.private_key = private_key

        super().initialize_terraform(instance, created)


    def finalize_terraform(self, instance):
        super().finalize_terraform(instance)
        self.delete_aws_ec2_keypair(instance.subnet.network, instance.config['key_name'])


    def start(self):
        instance = self.check_instance('server start')
        instance_id = instance.variables['instance_id']
        ec2 = self.ec2(instance.subnet.network)

        ec2.start_instances(InstanceIds = [instance_id])
        waiter = ec2.get_waiter('instance_running')
        waiter.wait(InstanceIds = [instance_id])

        self.command.success("Server {} has been started".format(instance.name))

    def stop(self):
        instance = self.check_instance('server stop')
        instance_id = instance.variables['instance_id']
        ec2 = self.ec2(instance.subnet.network)

        ec2.stop_instances(InstanceIds = [instance_id])
        waiter = ec2.get_waiter('instance_stopped')
        waiter.wait(InstanceIds = [instance_id])

        self.command.success("Server {} has been stopped".format(instance.name))
