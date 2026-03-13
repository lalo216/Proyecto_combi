Actualmente tenemos dos apps que hacen cosas muy diferentes, la "prueba_simpledb" y "prueba_generador_ruta". 
_Lo que hace cada una_

*prueba_simpledb*
Una aplicacion cual asume que esta siendo corrida desde un dispositivo android, esto lo permite inicializar y sembrar la bd usando sql tradicional

*prueba_generador_ruta*
Una aplicacion cual, de su propia forma intenta darle la memoria de paradas mediante una lista estatica.

>Colores
Generalmente cuando pedimos un color o paleta, la pelata esta en RGB, flutter necesita que sea HEX, lo cual brinda la duda ¿Para que ocupamos el color? Si es para organizacion, buscamos agregar una capa de traduccion para que se pueda saber el color de una ruta maso asi: "SELECT color FROM Paradas color". Si el color de una parada es nomas el de su padre (ruta) entonces debemos quidar que al llamar ese color se convierta otra vez.

>                       <
En pocas palabras, para que podamos dibujar una ruta, tomando las paradas como los puntos de referencia, debemo...
ok si alc ya me voy a mimir.