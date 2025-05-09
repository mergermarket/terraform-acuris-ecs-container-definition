import json
import os
import shutil
import tempfile
import time
import unittest
from subprocess import check_call, check_output

REGION = 'eu-west-1'

cwd = os.getcwd()


class TestContainerDefinition(unittest.TestCase):

    def setUp(self):
        self.workdir = tempfile.mkdtemp()
        self.module_path = f'{os.getcwd()}/test/infra'

        check_call(['terraform', 'init', self.module_path], cwd=self.workdir)
        check_call(['terraform', 'get', self.module_path], cwd=self.workdir)

    def tearDown(self):
        print('Tearing down')
        check_call(
            ['terraform', 'destroy', '-force', '-auto-approve'] +
            self.last_args + [self.module_path],
            cwd=self.workdir
        )

        if os.path.isdir(self.workdir):
            shutil.rmtree(self.workdir)

    def _apply_and_parse(self, variables, varsmap={}):
        varsmap_file = os.path.join(self.workdir, 'varsmap.json')
        with open(varsmap_file, 'w') as f:
            f.write(json.dumps(varsmap))

        args = sum(
            [
                ['-var', '{}={}'.format(key, val)]
                for key, val in variables.items()
            ], []
        )
        print('args', args)

        args += ['-var-file', varsmap_file]

        self.last_args = args

        check_call(
            ['terraform', 'apply', '-no-color', '-auto-approve'] + args + [self.module_path],
            cwd=self.workdir
        )

        output = check_output(
            ['terraform', 'output', '-json', 'rendered'],
            cwd=self.workdir
        ).decode('utf8')

        print('output', output)
        parsed_output = json.loads(output)
        parsed_definition = json.loads(parsed_output)
        return parsed_definition

    def test_is_a_valid_json(self):
        # Given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'container_port': 8001,
            'nofile_soft_ulimit': 1000
        }

        varsmap = {'labels': {"label1": "value1"},
            'extra_hosts': [{"host1":"10.0.1.1"}]}

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert definition['name'] == variables['name']
        assert definition['image'] == '123'
        assert definition['cpu'] == 1024
        assert definition['memory'] == 1024
        assert definition['essential']

        assert {
            'softLimit': 1000, 'name': 'nofile',
            'hardLimit': 65535
        } in definition['ulimits']
        assert {'containerPort': 8001} in definition['portMappings']
        assert {'extraHosts': [{'host1': '10.0.1.1'}]}

    def test_override_port_mappings(self):
        # Given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'nofile_soft_ulimit': 1000
        }
        varsmap = {
            'port_mappings': '[{"containerPort":7654}]'
        }

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert [{'containerPort': 7654}] == definition['portMappings']

    def test_labels(self):
        # Given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'container_port': 8001
        }
        varsmap = {
            'labels': {
                'label_key_1': 'label_value_1',
                'label_key_2': 'label_value_2',
            }
        }

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert {
            'name': 'LABEL_KEY_1',
            'value': 'label_value_1'
            } not in definition['environment']
        assert {
            'name': 'LABEL_KEY_2',
            'value': 'label_value_2'
            } not in definition['environment']

        for key in varsmap['labels']:
            assert varsmap['labels'][key] in definition['dockerLabels'][key]

    def test_container_env(self):
        # given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'container_port': 8001
        }
        varsmap = {
            'container_env': {
                'VAR1': 'value_1',
                'VAR2': 'value_2',
            }
        }

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert {
            'name': 'VAR1',
            'value': 'value_1'
            } in definition['environment']
        assert {
            'name': 'VAR2',
            'value': 'value_2'
            } in definition['environment']

    def test_mountpoint_not_set(self):
        # given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'container_port': 8001
        }
        varsmap = {}

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert [] == definition['mountPoints']

    def test_mountpoint_no_readonly(self):
        # given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'container_port': 8001
        }
        varsmap = {
            'mountpoint': {
                'sourceVolume': 'data_volume',
                'containerPath': '/mnt/data'
            }
        }

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert [{
            'containerPath': '/mnt/data',
            'sourceVolume': 'data_volume',
            'readOnly': False
            }] == definition['mountPoints']

    def test_mountpoint_readonly(self):
        # given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'container_port': 8001
        }
        varsmap = {
            'mountpoint': {
                'sourceVolume': 'data_volume',
                'containerPath': '/mnt/data',
                'readOnly': 'true'
            }
        }

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert [{
            'containerPath': '/mnt/data',
            'sourceVolume': 'data_volume',
            'readOnly': True
            }] == definition['mountPoints']

    def test_init_process_enabled(self):
        # given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024,
            'container_port': 8001
        }
        varsmap = {}

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert definition['linuxParameters']['initProcessEnabled']

    def test_command(self):
        # Given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024
        }
        varsmap = {
            'command': ["/bin/bash", "-c", "cat"]
        }

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert definition['name'] == variables['name']
        assert definition['image'] == '123'
        assert definition['cpu'] == 1024
        assert definition['memory'] == 1024
        assert definition['command'] == ["/bin/bash", "-c", "cat"]

    def test_command_empty(self):
        # Given
        variables = {
            'name': 'test-' + str(int(time.time() * 1000)),
            'image': '123',
            'cpu': 1024,
            'memory': 1024
        }
        varsmap = {
            'command': []
        }

        # when
        definition = self._apply_and_parse(variables, varsmap)

        # then
        assert definition['name'] == variables['name']
        assert definition['image'] == '123'
        assert definition['cpu'] == 1024
        assert definition['memory'] == 1024
        assert definition['command'] is None


class TestEncodeSecrets(unittest.TestCase):

    def test_encode_secrets(self):
        secrets_value = json.dumps({'Val1': 'some-secret-arn'})
        secrets = {'secrets': secrets_value}
        j = json.dumps(secrets)
        output = check_output(
            ['python', 'encode_secrets.py'],
            input=(str.encode(j))
        )
        expected = [{'name': 'Val1', 'valueFrom': 'some-secret-arn'}]
        actual = json.loads(output.decode())
        secrets = json.loads(actual['secrets'])
        assert secrets == expected

    def test_encode_common_secrets(self):
        secrets_value = json.dumps({'Val1': 'some-secret-arn'})
        secrets = {'common_secrets': secrets_value}
        j = json.dumps(secrets)
        output = check_output(
            ['python', 'encode_secrets.py'],
            input=(str.encode(j))
        )
        expected = [{'name': 'Val1', 'valueFrom': 'some-secret-arn'}]
        actual = json.loads(output.decode())
        secrets = json.loads(actual['secrets'])
        assert secrets == expected

    def test_encode_all_secrets(self):
        secrets_value = json.dumps({'Val1': 'some-secret-arn'})
        common_secrets_value = json.dumps({'Val2': 'some-secret-arn'})
        secrets = {
            'secrets': secrets_value,
            'common_secrets': common_secrets_value
        }
        j = json.dumps(secrets)
        output = check_output(
            ['python', 'encode_secrets.py'],
            input=(str.encode(j))
        )
        expected = [
            {'name': 'Val1', 'valueFrom': 'some-secret-arn'},
            {'name': 'Val2', 'valueFrom': 'some-secret-arn'}
        ]
        actual = json.loads(output.decode())
        secrets = json.loads(actual['secrets'])
        assert secrets == expected

    def test_no_secrets(self):
        secrets = {
            'secrets': json.dumps({}),
            'common_secrets': json.dumps({})
        }
        j = json.dumps(secrets)
        output = check_output(
            ['python', 'encode_secrets.py'],
            input=(str.encode(j))
        )
        expected = [
        ]
        actual = json.loads(output.decode())
        secrets = json.loads(actual['secrets'])
        assert secrets == expected
