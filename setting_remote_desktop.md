sudo apt update && sudo apt -y install wget unzip screen xfce4 firefox tightvncserver


sudo tightvncserver :1 && sudo wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && unzip ngrok-stable-linux-amd64.zip 

screen -R test 

./ngrok  tcp 5901 --authtoken 1nRjV2YVfJoRWV2qPKYV6sYvHov_2Aq95dvRJfJUjzJknCdn7 
