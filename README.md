# Projet Cloud ⛅
Robin Saint Georges, John Singhathip, Marion Hurteau

## Prérequis

- Un compte administrateur sur AWS.
- Une machine avec `terraform` installé, `ssh-keygen` installé, `awscli` installé et configuré (`aws configure`).
- Une connexion internet.



## Lancement du projet 

Clonez le présent projet.

Rendez vous dans le répertoire du projet.

Lancez `./deploy.sh`.

Si vous rencontrez un problème de droits, exécutez `chmod 777 deploy.sh` avant de l'exécuter.



Si vous souhaitez remettre le projet à zéro et détruire ce qui a été créé via `deploy.sh`, lancez `./destroy.sh`.



------------------------

Les fichiers sont grandement inspirés de cet article : https://medium.com/@aliatakan/terraform-create-a-vpc-subnets-and-more-6ef43f0bf4c1

## I - Terraform

> Faire en sorte que le code `terraform` ne porte pas les *secrets* nécessaires pour interagir avec la plateforme `AWS`.

Les credentials ne sont pas entrés en dur dans un fichier `.ts`, ils sont récupérés dans le dossier `.aws` de l'utilisateur grâce à main.tf:4 `shared_credentials_file = "$HOME/.aws/credentials"`.



> récupération **dynamique** de l'*ID* de l'`AMI` à utiliser

main.tf:8 `ami = data.aws_ami.ubuntu.id`



> construction de l'instance `EC2` avec un *user-data* basé sur le fichier [myUserData2.sh]

main.tf:10 `user_data = file("TP2/myUserData.sh")`



> construction du *security-group* nécessaire

network.tf:22

```
resource "aws_security_group" "ssh-allowed" {
    vpc_id = aws_vpc.prod-vpc.id
    
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${var.MY_IP}/32"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```



> construction d'un *load-balancer (ALB)* devant cette instance

main.tf:53

```
resource "aws_lb" "test_lb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.ubuntu_subnet_public.*.id
  
  enable_deletion_protection = false
}
```



> s'assurer que tout fonctionne

Dans la console, l'AMI apparaît bien dans EC2 > Instances > Instances, le LB apparaît bien dans EC2 > Load Balancing > Load Balancers.

Lors de la connexion en SSH (Par exemple `ssh -i "my-awesome-key-pair" ubuntu@ec2-15-236-158-119.eu-west-3.compute.amazonaws.com`), en lançant `sudo docker ps` on voit bien tous les containers tourner.



## II - Démarrage au déploiement et au reboot

> faire en sorte que le démarrage des *microservices* ait lieu au **déploiement aussi au \*reboot\*** de l'instance



## III - Architecture à trois étages

### 	1 - Frontend (webui & worker)

> il est constitué de *N* instances équivalentes. Comment mettre en œuvre plusieurs instances sans faire de gros copier/coller de code `terraform` ?

https://www.bogotobogo.com/DevOps/Terraform/Terraform-creating-multiple-instances-count-list-type.php

> on accède en `HTTP` à la *WebUI* **exclusivement** *via* un LB

> on accède en `SSH` directement aux instances depuis une adresse IP identifiée comme étant celle de l'administrateur

`ssh -i "my-awesome-key-pair" ubuntu@ec2-15-237-125-172.eu-west-3.compute.amazonaws.com`

> le démarrage des *containers* est piloté par *user-data* et loud-init_

### 	2 - Backend (rng & hasher)

> il est constitué de *N* instances équivalentes

> on accède en `HTTP` aux *microservices* **exclusivement** ia_ un `ALB` et exclusivement depuis les instances de l'étage rontend".

> on accède en `SSH` directement aux instances **depuis une resse IP identifiée comme étant celle de l'administrateur

> le démarrage des *containers* est piloté par *user-data* et loud-init_

### 	3 - Redis

> l'étage *"redis"* s'appuie sur le service managé `elasticache` plutôt que sur des instances `EC2` 

