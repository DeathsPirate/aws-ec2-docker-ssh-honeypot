# Installation Walkthough

Let's get started with a walkthrough of the setup

## AWS Prerequisites

## Infrastructure

### EC2
Firstly setup the EC2 instance (we can continue to do the next bits while it's spinning up)
- Go to https://console.aws.amazon.com/ec2/v2/home
- Select `Launch Instance` 
- Search for `ami-0f9cf087c1f27d9b1` this is the Ubuntu 16.04 instance with SSD volume type that I tested on. (You could use another debian based image but I've not tested on those) Then hit `Select`
- This runs fine in the `free tier` (t2.micro) so select that and hit `Review and Launch`
- Under **Security Groups** hit `Edit security groups` and `Add Rule`
    - You want to add  
            - Type `Custom TCP Rule`  
            - Protocol `TCP`  
            - Port Range `2222`  
            - Source `Custom` and then your IP Address eg `111.222.333.444/32`
    - You'll want to edit port 22 to be your IP Address aswell (For now, we'll change it back later)
 - Click `Review and Launch`, then `Launch`
 - Choose or Create a new key pair for using to SSH into the instance then hit `Launch Instances`

While that's being provisioned let's continue.

### S3 

Next setup the S3 bucket, this will be used to hold container images.  It's fairly straightforward:
- Go to https://s3.console.aws.amazon.com/s3/home
- Create Bucket
- Give the bucket a name eg. `docker-honeypot-images` names have to be unique across all of AWS so bear that in mind.  
- Select the Region
- If you're happy with the defaults hit `Next`, `Next`, `Next`, `Create Bucket` 

### CloudWatch Logs

Next up is to create the CloudWatch Log Groups we are going to use to store the logging information:
- Go to https://console.aws.amazon.com/cloudwatch/home
- Click `Logs` in the left menu then select `Create Log Group` from the `Actions` drop down menu.

***It's easier to create the access policies later on if all your honeypot log groups start the same eg `honeypot-`***

- Give your log group a name eg `honeypot-ssh-docker-start`
- Repeat to create two more log groups (eg):  
    - `honeypot-ssh-failed-attempts`  
    - `honeypot-ssh-commands`     
- Make a note of the ARN that is on the logs, we will need that later.  It should look something like:  
`arn:aws:logs:[YOUR CHOSEN REGION]:[YOUR ACCOUNT ID]:log-group:[YOUR LOG NAME]:*` 

## IAM 

### IAM Policies

Now we need to create an IAM user that we will use to only have write access to the S3 bucket and CloudWatch Logs.  The credentials are stored on the Honeypot host so just incase we want those credentials to have the least needed priviledges.
- Go to https://console.aws.amazon.com/iam/home  

First thing we need to do here is create our S3 policy:
- Select `Policies` from the left menu then `Create Policy`
- Next to **Service** select `Choose a service`
- Search for and click on `S3`
- Under **Access level** select `List` and `Write`
- Click on `Resources` then click `Add ARN` next to **bucket**
- Add the bucket name you created earlier then click `Add`
- Click on `Add ARN` next to **object**
- Add the bucket name you created earlier in the **Bucket name** field and check `Any` next to the **Object name** field then click `Add`
- Click on `Review Policy` at the bottom right
- Give the Policy a name eg `Honeypot-S3-WriteAccess`
- Click `Create Policy`

Next we need to create our CloudWatch Logs policy:
- Select `Create Policy`
- Next to **Service** select `Choose a service`
- Search for and click on `CloudWatch Logs`
- Under **Access level** select `List` and `Write`
- Click on `Resources` then click `Add ARN` next to **log-group**
- Add your region eg `us-east-2` to the **Region** box
- Add your account ID (you can see that in the ARN we got from the log group creation earlier) eg `987654321012` to the **Account** box
- For **Log group name** we can use a wild card to specify all the honeypot logs like `honeypot-*` if you named them that way (if not you'll have to create policies for each log name) 
- Hit `Add` then do the same for `Add ARN` next to **log-stream** but for **Log stream** and **Log stream name** just check `Any` next to both of those then hit `Add`
- Click on `Review Policy` at the bottom right
- Give the Policy a name eg `Honeypot-CWL-WriteAccess`
- Click `Create Policy`

### IAM Group

Next we create an IAM Group that we will attach our policies to:
- Select `Groups` in the left hand menu then click on `Create Group`
- Enter a group name eg `honeypot-group` in the **Group Name** box then hit `Next Step`
- Search for and tick the policies we created in the previous section eg `Honeypot-S3-WriteAccess` and `Honeypot-CWL-WriteAccess` then hit `Next Step` 
- Review the info then hit `Create Group`

### IAM User

Last step here is to create our user and attach the group to it:
- Select `Users` in the left menu then `Add User`
- Give the user a name eg `honeypot-user` in the **User name** field
- Select `Programmatic access` for the **Access type** then hit `Next: Permissions`
- Select `Add user to group` and then tick the group we created earlier then hit `Next: Tags`, `Next: Review`, and finally `Create user`
- Grab the **Access Key ID** and **Secret access key**

***This is your only chance to get the Secret access key so don't close the window until you've noted that down***

## Final Honeypot Setup

Our EC2 instance should be provisioned now.  We can go back to the EC2 management portal and select our instance then hit `Connect` this will give us the command needed to SSH into the instance and complete the next steps detailed in the README of the GitHub Repo. https://github.com/DeathsPirate/aws-ec2-docker-ssh-honeypot

# End of Part 1 (Part 2 will be adding a dashboard in CloudWatch)
