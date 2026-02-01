      *1. metadata -----------------
      *used by compiler/linker, not CPU
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HelloYuki.

      *4. logic -------------------
       PROCEDURE DIVISION.
           DISPLAY "Hello, Yuki!".
           STOP RUN.

      *----------hierarchy---------
      * division: indentidication, enviroment, data, procedure
      * section:
      *  data -> working-storage section, file section
      *  enviroment -> input-output section
      * paragraph
      * sentence
      * statement
      *---------format------------
      *| 1 sequence-num-area 6 | 7 | 8 A-area 11 | 12 B-area 72 |
      * 73 identification 80|
