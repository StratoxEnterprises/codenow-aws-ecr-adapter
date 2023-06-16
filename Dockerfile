FROM openjdk:11.0.3-jre-slim-stretch
COPY target/libs/*.jar app.jar
EXPOSE 80
CMD java -Xmx128m -Xms128m -XX:MaxMetaspaceSize=128m -Dlogback.configurationFile=logback-codenow.xml -Dconfig.file=/codenow/config/startup-message.txt -jar app.jar
