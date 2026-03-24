Actualmente tenemos dos apps que hacen cosas muy diferentes, la "prueba_simpledb" y "prueba_generador_ruta". 
_Lo que hace cada una_

*prueba_simpledb*
Una aplicacion cual asume que esta siendo corrida desde un dispositivo android, esto lo permite inicializar y sembrar la bd usando sql tradicional

*prueba_generador_ruta*
Una aplicacion cual, de su propia forma intenta darle la memoria de paradas mediante una lista estatica.

>Colores
Generalmente cuando pedimos un color o paleta, la pelata esta en RGB, flutter necesita que sea HEX, lo cual brinda la duda ¿Para que ocupamos el color? Si es para organizacion, buscamos agregar una capa de traduccion para que se pueda saber el color de una ruta maso asi: "SELECT color FROM Paradas color". Si el color de una parada es nomas el de su padre (ruta) entonces debemos quidar que al llamar ese color se convierta otra vez.

>                       <
La app tendra una api hecha con principios rest. Esto cambia todo, vamos a empezar reconociendo los limites de nuetra app como producto de demuestra.
 Se asume que tendremos > 100 usuarios a la vez, este numero se puede tomar como la escala en general.
 Los componentes que usaremos deben ser hechos con el estilo mobil en mente, por lo cual podemos enviar informacion a un servidor o propedor encriptado y mientras que
 ese paquete tenga informacion superficial que lo identifiqeu, el servidor puede correr un algoritmo (o aun mejor,chequeo contra llave predefinada) que la decripta, acepta y reencripta para que el usuario
 accede a su cuenta.
 Podemos cachear nada de eso, lo que si, seria el estilo que implementemos para la funcionalidad relacionada con la app (el uso de rutas), nuestro metodo de desarrollo simplemente no toca produccion, no subiremos
 actualizaciones sin pruebas a la bd de "produccion", por lo que las pruebas son corridas dentro de un emulador suena apto que si, por ejemplo, un miembro del equipo sube un cambio a la bd que cambia 100 filas, mientras que otro la esta usando, habran errores. In order to handle this we need to apply grain control to our bd changes and bare in mind that user changes (held on a theoretical user database) and functionality changes (held on a theoretical combis/routes bd) would likely be done differently. I recommend we first implement the functionality bd, which ill desing now, it should be able to conduct changes on a temp copy of the database that are then compared against a bd template for safety/sanity and if passed are applied to a previously empty bd on my server.