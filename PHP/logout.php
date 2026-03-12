<?php
session_start();
session_destroy(); // Destruye todos los datos de la sesión
header("Location: index.php"); // Te devuelve al login
exit();
?>
