data "ibm_is_image" "iac_image" {
  name = var.image_name
}

resource "ibm_is_instance" "iac_test_instance" {
  name    = "${var.project_name}-${var.environment}-instance"
  image   = data.ibm_is_image.iac_image.id
  resource_group  = data.ibm_resource_group.group.id
  profile = var.profile

  primary_network_interface {
    name            = "eth0"
    subnet          = ibm_is_subnet.iac_test_subnet.id
    security_groups = [ibm_is_security_group.iac_test_security_group.id]
  }

  vpc  = ibm_is_vpc.iac_test_vpc.id
  zone = var.zone
  keys      = [ibm_is_ssh_key.public_key.id]

  user_data = file("${path.module}/tfscripts/setup.sh")

  tags = ["iac-${var.project_name}-${var.environment}"]
}

# extra disk path, create volume and add to vsi, format and mount on /home
resource "ibm_is_volume" "iac_app_volume" {
  count    = var.home_fs_size > 0 ? 1 : 0
  name     = "${var.project_name}-${var.environment}-volume-01"
  resource_group  = data.ibm_resource_group.group.id
  profile  = "5iops-tier"
  zone     = var.zone
  capacity = var.home_fs_size
}

resource "ibm_is_instance_volume_attachment" "iac_attach_app_volume" {

  depends_on = [ ibm_is_floating_ip.iac_test_floating_ip ]

  count    = var.home_fs_size > 0 ? 1 : 0
  instance = ibm_is_instance.iac_test_instance.id
  name = "${var.project_name}-${var.environment}-volume-01-att"
  volume = ibm_is_volume.iac_app_volume[0].id

}
