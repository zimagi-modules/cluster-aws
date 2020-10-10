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
