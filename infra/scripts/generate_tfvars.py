import yaml
import sys

def yaml_to_tfvars(yaml_file, tfvars_file):
    """Converts a YAML file to a Terraform .tfvars file."""
    with open(yaml_file, 'r') as f:
        try:
            data = yaml.safe_load(f)
        except yaml.YAMLError as e:
            print(f"Error parsing YAML file: {e}")
            sys.exit(1)

    with open(tfvars_file, 'w') as f:
        for key, value in data.items():
            if isinstance(value, str):
                f.write(f'{key} = "{value}"\n')
            elif isinstance(value, bool):
                f.write(f'{key} = {str(value).lower()}\n')
            else:
                f.write(f'{key} = {value}\n')

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python generate_tfvars.py <input.yaml> <output.tfvars>")
        sys.exit(1)

    yaml_to_tfvars(sys.argv[1], sys.argv[2])
