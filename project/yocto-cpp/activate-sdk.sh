# Constants
CONST_SDK_BASE_DIR="/opt/poky"
CONST_SDK_VERSION="5.3.3"

# Check sourcing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  script_name="$(basename "$0")"
  echo "FAIL: SDK cannot be activated, use 'source $script_name' or '. $script_name'"
  exit 1
fi

# Check SDK directory exists
sdk_dir=$CONST_SDK_BASE_DIR/$CONST_SDK_VERSION
if [[ ! -d $sdk_dir ]]; then
  echo "FAIL: SDK not found, expected in ${sdk_dir}"
  return 1
fi

# Check SDK setup exists
sdk_setup_script=$(command ls $sdk_dir | grep ^environment-setup-)
if [[ -z $sdk_setup_script ]]; then
  echo "FAIL: Environment setup script not exist in ${sdk_dir}"
  return 1
fi

# Source SDK setup
sdk_setup_path=$sdk_dir/$sdk_setup_script
source $sdk_setup_path
echo "SDK ${CONST_SDK_VERSION} activated"
