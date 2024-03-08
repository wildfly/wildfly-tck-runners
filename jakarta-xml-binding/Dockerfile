# Reference: https://docs.docker.com/engine/reference/builder/

FROM fedora:39
RUN ["dnf", "upgrade", "--refresh", "-y"]
RUN ["dnf", "install", "-y", "bash-completion", "ant", "java-21-openjdk", "java-21-openjdk-devel", "java-21-openjdk-jmods", "java-latest-openjdk", "java-latest-openjdk-devel", "java-latest-openjdk-jmods", "maven", "maven-openjdk11", "git", "git-extras", "wget", "unzip", "procps-ng", "file"]

RUN ["useradd", "-u", "185", "-m", "jboss"]
COPY --chown=jboss:jboss --chmod=0755 bin/* /home/jboss/bin/

ENV PATH="/home/jboss/bin/:${PATH}"

USER jboss
WORKDIR /home/jboss


ENV HOME="/home/jboss"
ENV WORK_DIR="${HOME}"

RUN TCK_ZIP="${WORK_DIR}/jakarta-xml-binding-tck-4.0.2.zip"; \
    wget https://download.eclipse.org/jakartaee/xml-binding/4.0/jakarta-xml-binding-tck-4.0.2.zip; \
    unzip "${TCK_ZIP}"

# Add aliases
COPY --chown=jboss:jboss --chmod=0700 jboss-bashrc "${HOME}/.bashrc"

CMD ["/bin/bash"]
