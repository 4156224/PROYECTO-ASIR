<?php
$servidor = "localhost";
$usuario_db = "andres"; // Mi usuario de phpMyAdmin
$password_db = "andres"; // Mi contraseña de phpMyAdmin
$nombre_db = "gestion_incidencias";

$conexion = mysqli_connect($servidor, $usuario_db, $password_db, $nombre_db);

if (!$conexion) {
    die("Error de conexión: " . mysqli_connect_error());
}
?>
