#####

--> When You Want To Work With The `Terraform`, First You Need To `Install Terraform` In Your System.
        - Just Go Through This Link To Install `terraform`(https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
        - After Installation Is Done Just Check The `terraform version`,By Using Below Command
            * `terraform --version`. Once You Seen The Terraform Version You Have Successfully Installed It.
        
--> After `Terraform` Installation Completed. You Need To Install `Aws Cli`.
        - You Need To Install `unzip` First.
        - Just Go Through This Link To Install `Aws Cli`(https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
        - After `Aws Cli` Sucessfully Installed. You Need To Configure The `Aws Access Key` & `Aws Secret Key`
            - In Aws Console, Go To `IAM` 
                - Create One User Group And One User And Add That User To The User Group Which You Created First.
                - And Give Permission As `Adminstartor Acess` To That User Group.
                - Go To User Section for `Security Credentails` and Create `Access Key` & `Secret Key`. Download the `.csv` File.
        - After All This Go To System Where You Installed `Terraform`, There You have To Enter One Command
            - `aws configure`. Here, You Have To Give Your `Acces Key` & `Secret Key`.

--> If You Done Above Steps Are Correctly. Then You Can Go With The Below Commands,
        - `terraform init`
        - `terraform validate`
        - `terraform apply`. Here, You Need To Enter The Variables Names Of Required Things.
        - After Your Work is Done. You Can Tear The Whole The Infrastructure With Below Command,
            - `terraform destroy`.


