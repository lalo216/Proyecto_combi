al parecer flutter no se puede conextar directamente, se necesita crear una "api"
que se encargue de ser el intermediario entre flutter y la base.
esto lo podemos hacer facilmente con php, primero tenemos que entrar a htdocs en la carpeta
de xampp, crear una carpeta donde vamos a alojar el "api",
despues creamos el archivo php y un ejemplo que se conecte a la base de datos, en este caso
cree una base de datos local con mysql y despues ingrese las credenciales para conectarme 
a la bd (nota: es importante agregar en el header las lineas que permitiran el acceso a la bd
desde cualquier parte).
al final la conexion se hace como en html por ejemplo 