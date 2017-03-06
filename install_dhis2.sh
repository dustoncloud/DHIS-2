# Dhis Installation in Debain 8.0 machine
#!/usr/bin/env bash

# Creates new dhis user
createDhisUser() {
    echo "######################## Creating new user ##########################"

    # create user with given home directory and shell
    useradd -d /home/dhis -m dhis -s /bin/bash

    # Add dhis to user group with right to use sudo
    usermod -G sudo dhis
}

# Installs PostgreSQL, creates user/role and database
installPostgreSQL() {
    echo "######################### PostgreSQL  ##########################"

    # Install database from ubuntu's PPA
    apt-get -y -q install postgresql postgresql-contrib

    # Create new database user
    su -c 'psql -c "CREATE USER dhis WITH PASSWORD '"'district'"'"' postgres

    # Create new database
    su -c 'psql -c "CREATE DATABASE dhis2 WITH OWNER dhis"' postgres
}

# Installs Oracle JDK and sets JAVA_HOME environment variable
# Installation valid only for Debian machine
	echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
	echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
	apt-get update
	apt-get -y install oracle-java8-installer

# Installs Tomcat
installTomcat() {
    echo "############################## Tomcat ##############################"

    # Install Tomcat server
    apt-get -y -q install tomcat7-user

    # Create tomcat user
    tomcat7-instance-create /home/dhis/web-dhis/

    # Setting JAVA_HOME environment variable
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle/" >> /home/dhis/web-dhis/bin/setenv.sh

    # Giving more memory to JVM
    echo "export JAVA_OPTS='-Xmx750m -Xms400m'" >> /home/dhis/web-dhis/bin/setenv.sh

    # Export DHIS2_HOME environment variable which points to configuration
    echo "export DHIS2_HOME=/home/dhis/config" >> /home/dhis/web-dhis/bin/setenv.sh
}

# Create hibernate configuration file for DHIS2
createHibernateConfiguration() {
    echo "##################### Creating hibernate configuration  #########################"

    # Create dhis configuration directory
    mkdir /home/dhis/config

    # Create dhis configuration file
    touch /home/dhis/config/dhis.conf

    # Hibernate SQL dialect
    echo "connection.dialect = org.hibernate.dialect.PostgreSQLDialect" >> /home/dhis/config/dhis.conf

    # JDBC driver class
    echo "connection.driver_class = org.postgresql.Driver" >> /home/dhis/config/dhis.conf

    # JDBC driver connection URL
    echo "connection.url = jdbc:postgresql:dhis2" >> /home/dhis/config/dhis.conf

    # Database username
    echo "connection.username = dhis" >> /home/dhis/config/dhis.conf

    # Database password
    echo "connection.password = district" >> /home/dhis/config/dhis.conf

    # Database schema behavior, can be validate, update, create, create-drop
    echo "connection.schema = update" >> /home/dhis/config/dhis.conf

    # Encryption password (sensitive)
    echo "encryption.password = district" >> /home/dhis/config/dhis.conf
}

# Download dhis.war
downloadDhisWar() {
   echo "############## Downloading DHIS2 war file  ##################"

    #Download .war file
   wget --no-check-certificate --progress=bar https://www.dhis2.org/download/releases/2.26/dhis.war -O /home/dhis/web-dhis/webapps/ROOT.war
}

# Force tomcat to start on boot script
configureTomcat() {
    echo "############## Configuring Tomcat  #####################"

    touch /etc/init.d/tomcat

    # Printing to file
    echo "#!/bin/sh" >> /etc/init.d/tomcat
    echo "" >> /etc/init.d/tomcat

    echo "case \$1 in" >> /etc/init.d/tomcat

    echo "start)" >> /etc/init.d/tomcat
    echo "    sh /home/dhis/web-dhis/bin/startup.sh" >> /etc/init.d/tomcat
    echo ";;" >> /etc/init.d/tomcat

    echo "stop)" >> /etc/init.d/tomcat
    echo "    sh /home/dhis/web-dhis/bin/shutdown.sh" >> /etc/init.d/tomcat
    echo ";;" >> /etc/init.d/tomcat

    echo "restart)" >> /etc/init.d/tomcat
    echo "    sh /home/dhis/web-dhis/bin/shutdown.sh" >> /etc/init.d/tomcat
    echo "    sleep 5" >> /etc/init.d/tomcat
    echo "    sh /home/dhis/web-dhis/bin/startup.sh" >> /etc/init.d/tomcat
    echo ";;" >> /etc/init.d/tomcat

    echo "esac" >> /etc/init.d/tomcat
    echo "exit 0" >> /etc/init.d/tomcat

    # Make sure the tomcat init script will be invoked 
    # during system startup and shutdown:
    chmod +x /etc/init.d/tomcat
    /usr/sbin/update-rc.d -f tomcat defaults 81
}

# Start DHIS2 instance
startDhis2Instance() {
    sh /home/dhis/web-dhis/bin/startup.sh
}


installDhis2Instance() {
    # Update repos first
    apt-get -qq update

    createDhisUser
    installPostgreSQL
    installOracleJdk
    installTomcat
    createHibernateConfiguration
    downloadDhisWar
    configureTomcat
    startDhis2Instance
}


# Start installation Instance
installDhis2Instance

#  Instalation Completed please browse https://ip-address:8080
