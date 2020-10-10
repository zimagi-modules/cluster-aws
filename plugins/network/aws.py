from systems.plugins.index import BaseProvider


class SubnetProvider(BaseProvider('network.subnet', 'aws')):

    def initialize_terraform(self, instance, created):
        if instance.config['zone'] is None and instance.config['zone_suffix'] is not None:
            instance.config['zone'] = "{}{}".format(
                instance.network.config['region'],
                instance.config['zone_suffix']
            )
        super().initialize_terraform(instance, created)
