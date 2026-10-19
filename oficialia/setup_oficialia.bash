#!/usr/bin/env bash
# ==============================================================================
# Script Generador de Arquitectura y Base de Datos Automática
# Proyecto: SIJ - Módulo Principal Oficialía de Partes (Tomcat 10 + MySQL + Java 21)
# Uso (en Git Bash en Windows, o Terminal en Mac/Linux):
#   bash setup_oficialia.sh
# ==============================================================================

set -e

echo "🚀 Creando arquitectura de carpetas para Oficialía de Partes (Java 21)..."

# 1. Estructura Backend (Arquitectura MVC / N-Capas para Servlets)
mkdir -p src/main/java/mx/edu/utez/oficialia/config
mkdir -p src/main/java/mx/edu/utez/oficialia/model
mkdir -p src/main/java/mx/edu/utez/oficialia/dao
mkdir -p src/main/java/mx/edu/utez/oficialia/service
mkdir -p src/main/java/mx/edu/utez/oficialia/controller/admin
mkdir -p src/main/java/mx/edu/utez/oficialia/controller/api
mkdir -p src/main/java/mx/edu/utez/oficialia/controller/auth
mkdir -p src/main/java/mx/edu/utez/oficialia/util

# 2. Recursos (SQL auto-ejecutable al arrancar Tomcat)
mkdir -p src/main/resources/sql

# 3. Estructura Frontend (HTML5 + CSS Variables + Bootstrap + JS Vanilla)
mkdir -p src/main/webapp/assets/css
mkdir -p src/main/webapp/assets/js
mkdir -p src/main/webapp/assets/img
mkdir -p src/main/webapp/views/admin
mkdir -p src/main/webapp/views/oficialia
mkdir -p src/main/webapp/WEB-INF

# 4. GitHub Actions para proteger Pull Requests
mkdir -p .github/workflows

# ==============================================================================
# Archivo 1: pom.xml (Listo para Java 21, Tomcat 10 / Jakarta EE 10, MySQL y Gson)
# ==============================================================================
cat << 'EOF' > pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>mx.edu.utez</groupId>
    <artifactId>sij-oficialia-partes</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>war</packaging>
    <name>SIJ - Oficialia de Partes</name>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.target>21</maven.compiler.target>
        <maven.compiler.source>21</maven.compiler.source>
    </properties>

    <dependencies>
        <!-- Jakarta Servlet API para Apache Tomcat 10 -->
        <dependency>
            <groupId>jakarta.servlet</groupId>
            <artifactId>jakarta.servlet-api</artifactId>
            <version>6.0.0</version>
            <scope>provided</scope>
        </dependency>

        <!-- Driver MySQL -->
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <version>8.3.0</version>
        </dependency>

        <!-- Gson para Endpoints JSON entre los 4 equipos -->
        <dependency>
            <groupId>com.google.code.gson</groupId>
            <artifactId>gson</artifactId>
            <version>2.10.1</version>
        </dependency>
    </dependencies>

    <build>
        <finalName>oficialia</finalName>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-war-plugin</artifactId>
                <version>3.4.0</version>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# ==============================================================================
# Archivo 2: schema.sql (Se ejecuta SOLO al iniciar Tomcat, sin usar Workbench)
# ==============================================================================
cat << 'EOF' > src/main/resources/sql/schema.sql
CREATE TABLE IF NOT EXISTS configuracion_visual (
    id_config INT PRIMARY KEY DEFAULT 1,
    color_primario VARCHAR(15) NOT NULL DEFAULT '#691C32',
    color_secundario VARCHAR(15) NOT NULL DEFAULT '#BC955C',
    logo_login VARCHAR(255) DEFAULT 'assets/img/logo_login.png',
    logo_menu VARCHAR(255) DEFAULT 'assets/img/logo_menu.png',
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS materias (
    id_materia INT AUTO_INCREMENT PRIMARY KEY,
    nombre_materia VARCHAR(80) NOT NULL UNIQUE,
    activo TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS distritos (
    id_distrito INT AUTO_INCREMENT PRIMARY KEY,
    nombre_distrito VARCHAR(120) NOT NULL UNIQUE,
    id_distrito_cercano INT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_distrito_cercano FOREIGN KEY (id_distrito_cercano) REFERENCES distritos(id_distrito)
);

CREATE TABLE IF NOT EXISTS juzgados (
    id_juzgado INT AUTO_INCREMENT PRIMARY KEY,
    numero_juzgado VARCHAR(15) NOT NULL UNIQUE,
    nombre_juzgado VARCHAR(120) NOT NULL,
    id_distrito INT NOT NULL,
    id_materia INT NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_juzgado_distrito FOREIGN KEY (id_distrito) REFERENCES distritos(id_distrito),
    CONSTRAINT fk_juzgado_materia FOREIGN KEY (id_materia) REFERENCES materias(id_materia)
);

CREATE TABLE IF NOT EXISTS salas_segunda_instancia (
    id_sala INT AUTO_INCREMENT PRIMARY KEY,
    nombre_sala VARCHAR(100) NOT NULL,
    nombre_magistrado VARCHAR(120) NOT NULL,
    id_distrito INT NOT NULL,
    disponible TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_sala_distrito FOREIGN KEY (id_distrito) REFERENCES distritos(id_distrito)
);

CREATE TABLE IF NOT EXISTS mesas_audiencia_ref (
    id_mesa INT AUTO_INCREMENT PRIMARY KEY,
    nombre_mesa VARCHAR(60) NOT NULL,
    id_juzgado INT NOT NULL,
    id_materia INT NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_mesa_juzgado FOREIGN KEY (id_juzgado) REFERENCES juzgados(id_juzgado),
    CONSTRAINT fk_mesa_materia FOREIGN KEY (id_materia) REFERENCES materias(id_materia)
);

CREATE TABLE IF NOT EXISTS usuarios_oficialia (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(80) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rol ENUM('ADMIN_GLOBAL', 'ADMIN_OFICIALIA', 'OPERADOR_OFICIALIA') NOT NULL DEFAULT 'OPERADOR_OFICIALIA',
    id_juzgado INT NULL,
    intentos_fallidos INT NOT NULL DEFAULT 0,
    bloqueado_hasta DATETIME NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_usuario_juzgado FOREIGN KEY (id_juzgado) REFERENCES juzgados(id_juzgado)
);

CREATE TABLE IF NOT EXISTS demandas_expedientes (
    id_expediente INT AUTO_INCREMENT PRIMARY KEY,
    folio_solicitud VARCHAR(30) NOT NULL UNIQUE,
    numero_expediente VARCHAR(30) NULL UNIQUE,
    curp_promovente VARCHAR(18) NOT NULL,
    nombre_promovente VARCHAR(150) NOT NULL,
    resumen_demanda TEXT NOT NULL,
    id_materia INT NOT NULL,
    id_juzgado INT NOT NULL,
    id_distrito INT NOT NULL,
    procede TINYINT(1) NULL,
    instancia ENUM('PRIMERA_INSTANCIA', 'SEGUNDA_INSTANCIA') NOT NULL DEFAULT 'PRIMERA_INSTANCIA',
    id_mesa_asignada INT NULL,
    folio_audiencia VARCHAR(30) NULL,
    id_sala_asignada INT NULL,
    estatus ENUM('EN_REVISION', 'PROCEDE_PRIMERA', 'PROCEDE_SEGUNDA', 'NO_PROCEDE') NOT NULL DEFAULT 'EN_REVISION',
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_exp_materia FOREIGN KEY (id_materia) REFERENCES materias(id_materia),
    CONSTRAINT fk_exp_juzgado FOREIGN KEY (id_juzgado) REFERENCES juzgados(id_juzgado),
    CONSTRAINT fk_exp_distrito FOREIGN KEY (id_distrito) REFERENCES distritos(id_distrito),
    CONSTRAINT fk_exp_mesa FOREIGN KEY (id_mesa_asignada) REFERENCES mesas_audiencia_ref(id_mesa),
    CONSTRAINT fk_exp_sala FOREIGN KEY (id_sala_asignada) REFERENCES salas_segunda_instancia(id_sala)
);

CREATE TABLE IF NOT EXISTS auditoria_historial (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_expediente INT NULL,
    usuario_responsable VARCHAR(80) NOT NULL,
    modulo_origen VARCHAR(50) NOT NULL DEFAULT 'OFICIALIA',
    campo_modificado VARCHAR(80) NOT NULL,
    valor_anterior VARCHAR(255) NULL,
    valor_nuevo VARCHAR(255) NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO configuracion_visual (id_config, color_primario, color_secundario) VALUES (1, '#691C32', '#BC955C');
INSERT IGNORE INTO materias (id_materia, nombre_materia) VALUES (1, 'Familiar'), (2, 'Violencia Familiar'), (3, 'Civil'), (4, 'Penal');
INSERT IGNORE INTO distritos (id_distrito, nombre_distrito, id_distrito_cercano) VALUES (1, 'Distrito 1 - Cuernavaca', NULL), (2, 'Distrito 2 - Xochitepec', 1);
INSERT IGNORE INTO juzgados (id_juzgado, numero_juzgado, nombre_juzgado, id_distrito, id_materia) VALUES (1, 'J01', 'Juzgado Primero Familiar', 1, 1), (2, 'J02', 'Juzgado Segundo Violencia', 2, 2);
INSERT IGNORE INTO salas_segunda_instancia (id_sala, nombre_sala, nombre_magistrado, id_distrito, disponible) VALUES (1, 'Primera Sala Segunda Instancia', 'Magistrado Titular Sala 1', 1, 1);
INSERT IGNORE INTO mesas_audiencia_ref (id_mesa, nombre_mesa, id_juzgado, id_materia) VALUES (1, 'Mesa 1 - Familiar', 1, 1), (2, 'Mesa 2 - Familiar', 1, 1), (3, 'Mesa 1 - Violencia', 2, 2);
INSERT IGNORE INTO usuarios_oficialia (id_usuario, usuario, password, rol, id_juzgado) VALUES (1, 'admin', 'admin123', 'ADMIN_OFICIALIA', 1);
EOF

# ==============================================================================
# Archivo 3: ConexionMySQL.java (Auto-crea la BD sij_oficialia si no existe)
# ==============================================================================
cat << 'EOF' > src/main/java/mx/edu/utez/oficialia/config/ConexionMySQL.java
package mx.edu.utez.oficialia.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexionMySQL {
    // createDatabaseIfNotExist=true crea la base de datos automaticamente sin abrir Workbench
    private static final String URL = "jdbc:mysql://localhost:3306/sij_oficialia?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Mexico_City";
    private static final String USER = "root";
    private static final String PASSWORD = "root"; // Cambiar si tu MySQL local tiene otra contrasena

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            return DriverManager.getConnection(URL, USER, PASSWORD);
        } catch (ClassNotFoundException e) {
            throw new SQLException("Error al cargar el driver de MySQL", e);
        }
    }
}
EOF

# ==============================================================================
# Archivo 4: DatabaseInitializer.java (Crea las tablas solas al arrancar Tomcat)
# ==============================================================================
cat << 'EOF' > src/main/java/mx/edu/utez/oficialia/config/DatabaseInitializer.java
package mx.edu.utez.oficialia.config;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Statement;
import java.util.stream.Collectors;

@WebListener
public class DatabaseInitializer implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("[SIJ-Oficialia] Verificando e inicializando tablas en MySQL...");
        try (Connection conn = ConexionMySQL.getConnection();
             Statement stmt = conn.createStatement();
             InputStream is = getClass().getClassLoader().getResourceAsStream("sql/schema.sql")) {

            if (is == null) {
                System.err.println("[SIJ-Oficialia] No se encontro sql/schema.sql");
                return;
            }

            String sqlScript = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))
                    .lines()
                    .filter(line -> !line.trim().startsWith("--"))
                    .collect(Collectors.joining("\n"));

            for (String command : sqlScript.split(";")) {
                if (!command.trim().isEmpty()) {
                    stmt.execute(command.trim());
                }
            }
            System.out.println("[SIJ-Oficialia] Base de datos y catalogos listos automaticamente.");
        } catch (Exception e) {
            System.err.println("[SIJ-Oficialia] Error al inicializar la base de datos: " + e.getMessage());
        }
    }
}
EOF

# ==============================================================================
# Archivo 5: variables.css (Personalizacion Visual del Admin Global)
# ==============================================================================
cat << 'EOF' > src/main/webapp/assets/css/variables.css
:root {
    --color-primario: #691C32;
    --color-secundario: #BC955C;
    --color-fondo: #F8F9FA;
    --color-texto: #212529;
}

.bg-institucional-primario {
    background-color: var(--color-primario) !important;
    color: #ffffff !important;
}

.btn-institucional {
    background-color: var(--color-primario);
    border-color: var(--color-primario);
    color: #ffffff;
}

.btn-institucional:hover {
    background-color: var(--color-secundario);
    border-color: var(--color-secundario);
    color: #ffffff;
}
EOF

# ==============================================================================
# Archivo 6: GitHub Action para bloquear PRs que no compilen (Java 21)
# ==============================================================================
cat << 'EOF' > .github/workflows/build.yml
name: Validar Compilacion Servlets
on:
  pull_request:
    branches: [ "main", "develop" ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configurar JDK 21
        uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: maven
      - name: Compilar con Maven
        run: mvn clean compile
EOF

# ==============================================================================
# Archivo 7: .gitignore limpio para Java / Maven / IDEs
# ==============================================================================
cat << 'EOF' > .gitignore
target/
*.war
.idea/
*.iml
.vscode/
.DS_Store
EOF

echo "✅ ¡Estructura completa y autoinicializador de MySQL (Java 21) creados con éxito!"