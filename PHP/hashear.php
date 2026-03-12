<?php
include 'conexion.php';

// 1. Creamos el hash seguro para la contraseña "1234"
$password_segura = password_hash("1234", PASSWORD_DEFAULT);

// 2. Actualizamos a TODOS los usuarios en la base de datos
$sql = "UPDATE usuarios SET password = '$password_segura'";

if (mysqli_query($conexion, $sql)) {
    echo "<h1>¡Éxito!</h1>";
    echo "<p>Todas las contraseñas se han encriptado correctamente.</p>";
    echo "<p>Ya puedes borrar este archivo y probar el Login.</p>";
} else {
    echo "Error: " . mysqli_error($conexion);
}
?>
