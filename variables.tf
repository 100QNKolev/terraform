variable "resource_group_location" {
    type = string
    description = "West Europe"
}


variable "source_control_git_url" {
    type = string
    description = "https://github.com/100QNKolev/TaskBoard"
}

variable "storage_account_name" {
    type = string
    description = "contactbooksa"
}

variable "server_admin_username" {
    type = string
    description = "missadministrator"
}

variable "server_admin_password" {
    type = string
    description = "thisIsKat11"
}

variable "database_name" {
    type = string
    description = "contactBookDB"
}

variable "firewall_name" {
    type = string
    description = "contactBookFR"
}