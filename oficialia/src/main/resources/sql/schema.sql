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
