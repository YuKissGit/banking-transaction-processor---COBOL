      *----------hierarchy---------
      * D: division: identification, environment, data, procedure
      * S: section:（optional）
      *    (data -> working-storage section, file section
      *    (environment -> input-output section
      * P: paragraph
      *    ST: statement



      *---------------------------------------------
       IDENTIFICATION DIVISION. *> D1 identification
       PROGRAM-ID. EOD.         *>    D1- program id

      *---------------------------------------------
       ENVIRONMENT DIVISION.    *>D2 environment
       INPUT-OUTPUT SECTION.    *>    D2-S1 input-output
       FILE-CONTROL.            *>          D2-S1-P1 file-control
           SELECT ACCT-MASTER ASSIGN TO "acct-master.dat" *>D2-S1-P1-ST 
                 ORGANIZATION IS LINE SEQUENTIAL.
      *only maps the logical file name to a path. COBOL doesn’t check
      * or create the file until OPEN is executed.
           SELECT TRANS-FILE   ASSIGN TO "trans.dat"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ACCT-NEW    ASSIGN TO "./output/acct-master-new.dat"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT REPORT-FILE ASSIGN TO "./output/report.txt"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT ERROR-FILE  ASSIGN TO "./output/error.log"
               ORGANIZATION IS LINE SEQUENTIAL.
       
      *---------------------------------------------
       DATA DIVISION.           *> D3 data

      *------------------------------------
       FILE SECTION.            *>    D3-S1
      *FD:file description, declare the file format, including in/out
       FD  ACCT-MASTER.         *>       D3-S1-P1  (file structure name)  
           01  ACCT-MASTER-REC.     *>      D3-S1-P1-ST(one line record)
               05  AM-ACCT-ID        PIC X(5). *>(record elem)
               05  AM-NAME           PIC X(10).
               05  AM-BALANCE        PIC 9(7)V99.
               05  AM-STATUS         PIC X(1).
      
           FD  TRANS-FILE.
           01  TRANS-REC.
               05  TR-ACCT-ID        PIC X(5).
               05  TR-TYPE           PIC X(1).
               05  TR-AMOUNT         PIC 9(7)V99.
      
           FD  ACCT-NEW.
           01  ACCT-NEW-REC.
               05  AN-ACCT-ID        PIC X(5).
               05  AN-NAME           PIC X(10).
               05  AN-BALANCE        PIC 9(7)V99.
               05  AN-STATUS         PIC X(1).
      
           FD  REPORT-FILE.
           01  REPORT-LINE           PIC X(80).
      
           FD  ERROR-FILE.
           01  ERROR-LINE            PIC X(120).
      *------------------------------------
       WORKING-STORAGE SECTION.                   *>    D3-S2
      *temporary variable for procedure
           01  EOF-MASTER            PIC X VALUE "N".    *>    D3-S2-ST
               88  MASTER-EOF               VALUE "Y".
           01  EOF-TRANS             PIC X VALUE "N".
               88  TRANS-EOF                VALUE "Y".
           
      *01  WS-CURRENT-ACCT-ID    PIC X(5) VALUE SPACES.
           
           01  WS-COUNTERS.
               05  WS-TRANS-READ     PIC 9(7) VALUE 0.
               05  WS-TRANS-OK       PIC 9(7) VALUE 0.
               05  WS-TRANS-FAIL     PIC 9(7) VALUE 0.
               05  WS-TOTAL-DEPOSIT  PIC 9(9)V99 VALUE 0.
               05  WS-TOTAL-WITHDRAW PIC 9(9)V99 VALUE 0.
           
           01  WS-REASON             PIC X(60).
           
           01  WS-AMOUNT-DISP        PIC ZZZ,ZZZ,ZZ9.99.
           01  WS-BALANCE-DISP       PIC ZZZ,ZZZ,ZZ9.99.
           01  WS-AMOUNT-DISP-STR    PIC X(15).
           01  WS-BALANCE-DISP-STR   PIC X(15).


      *---------------------------------------------
       PROCEDURE DIVISION.   *>    D4 procedure

       MAIN.                 *>    D4-P1
           PERFORM INIT-FILES*>       D4-P1-ST
           PERFORM READ-MASTER
           PERFORM READ-TRANS

           PERFORM UNTIL MASTER-EOF
               IF NOT TRANS-EOF AND AM-ACCT-ID = TR-ACCT-ID
                   PERFORM APPLY-ALL-TRANS-FOR-ACCOUNT
               END-IF

               PERFORM WRITE-UPDATED-MASTER
               PERFORM READ-MASTER
           END-PERFORM

           PERFORM WRITE-TRAILING-TRANS-ERRORS
           PERFORM WRITE-REPORT
           PERFORM CLOSE-FILES
           STOP RUN.

       INIT-FILES.                     *>    D4-P2
           OPEN INPUT  ACCT-MASTER          *>  D4-P2-ST
           OPEN INPUT  TRANS-FILE
           OPEN OUTPUT ACCT-NEW *>open output - if not exist create one
           OPEN OUTPUT REPORT-FILE
           OPEN OUTPUT ERROR-FILE.

       READ-MASTER.
           READ ACCT-MASTER
               AT END
                   MOVE "Y" TO EOF-MASTER
               NOT AT END
                   CONTINUE
           END-READ.

       READ-TRANS.
           READ TRANS-FILE *>read line by line, not entire file
               AT END
                   MOVE "Y" TO EOF-TRANS
               NOT AT END
                   ADD 1 TO WS-TRANS-READ
           END-READ.

       APPLY-ALL-TRANS-FOR-ACCOUNT.
           PERFORM UNTIL TRANS-EOF OR TR-ACCT-ID NOT = AM-ACCT-ID
               PERFORM VALIDATE-AND-APPLY-ONE-TRANS
               PERFORM READ-TRANS
           END-PERFORM.

       VALIDATE-AND-APPLY-ONE-TRANS.
           IF AM-STATUS = "F"
               MOVE "ACCOUNT FROZEN" TO WS-REASON
               PERFORM LOG-ERROR
               ADD 1 TO WS-TRANS-FAIL
               EXIT PARAGRAPH
           END-IF

           IF TR-TYPE NOT = "D" AND TR-TYPE NOT = "W"
               MOVE "INVALID TRANSACTION TYPE" TO WS-REASON
               PERFORM LOG-ERROR
               ADD 1 TO WS-TRANS-FAIL
               EXIT PARAGRAPH
           END-IF

           IF TR-AMOUNT = 0
               MOVE "ZERO AMOUNT NOT ALLOWED" TO WS-REASON
               PERFORM LOG-ERROR
               ADD 1 TO WS-TRANS-FAIL
               EXIT PARAGRAPH
           END-IF

           IF TR-TYPE = "D" *>deposit
               ADD TR-AMOUNT TO AM-BALANCE
               ADD TR-AMOUNT TO WS-TOTAL-DEPOSIT
               ADD 1 TO WS-TRANS-OK
               EXIT PARAGRAPH
           END-IF

           IF TR-TYPE = "W" *>withdraw
               IF AM-BALANCE < TR-AMOUNT
                   MOVE "INSUFFICIENT FUNDS" TO WS-REASON
                   PERFORM LOG-ERROR
                   ADD 1 TO WS-TRANS-FAIL
               ELSE
                   SUBTRACT TR-AMOUNT FROM AM-BALANCE
                   ADD TR-AMOUNT TO WS-TOTAL-WITHDRAW
                   ADD 1 TO WS-TRANS-OK
               END-IF
               EXIT PARAGRAPH
           END-IF.

       LOG-ERROR.
           MOVE SPACES TO ERROR-LINE
           MOVE TR-AMOUNT TO WS-AMOUNT-DISP
           STRING
               "ACCT=" TR-ACCT-ID
               " TYPE=" TR-TYPE
               " AMT=" WS-AMOUNT-DISP
               " REASON=" WS-REASON
               DELIMITED BY SIZE
               INTO ERROR-LINE
           END-STRING
           WRITE ERROR-LINE.

       WRITE-UPDATED-MASTER.
           MOVE AM-ACCT-ID TO AN-ACCT-ID
           MOVE AM-NAME    TO AN-NAME
           MOVE AM-BALANCE TO AN-BALANCE
           MOVE AM-STATUS  TO AN-STATUS
           WRITE ACCT-NEW-REC.

       WRITE-TRAILING-TRANS-ERRORS.
           PERFORM UNTIL TRANS-EOF
               MOVE "ACCOUNT NOT FOUND IN MASTER" TO WS-REASON
               PERFORM LOG-ERROR
               ADD 1 TO WS-TRANS-FAIL
               PERFORM READ-TRANS
           END-PERFORM.

       WRITE-REPORT.
           MOVE SPACES TO REPORT-LINE
           WRITE REPORT-LINE FROM "======== END OF DAY REPORT ========"

           MOVE WS-TRANS-READ TO WS-AMOUNT-DISP
           MOVE SPACES TO REPORT-LINE
           STRING "TOTAL TRANSACTIONS READ: " WS-AMOUNT-DISP
               DELIMITED BY SIZE INTO REPORT-LINE
           END-STRING
           WRITE REPORT-LINE

           MOVE WS-TRANS-OK TO WS-AMOUNT-DISP
           MOVE SPACES TO REPORT-LINE
           STRING "TOTAL SUCCESSFUL:        " WS-AMOUNT-DISP
               DELIMITED BY SIZE INTO REPORT-LINE
           END-STRING
           WRITE REPORT-LINE

           MOVE WS-TRANS-FAIL TO WS-AMOUNT-DISP
           MOVE SPACES TO REPORT-LINE
           STRING "TOTAL FAILED:            " WS-AMOUNT-DISP
               DELIMITED BY SIZE INTO REPORT-LINE
           END-STRING
           WRITE REPORT-LINE

           MOVE WS-TOTAL-DEPOSIT TO WS-AMOUNT-DISP
           MOVE SPACES TO REPORT-LINE
           STRING "TOTAL DEPOSIT AMOUNT:    " WS-AMOUNT-DISP
               DELIMITED BY SIZE INTO REPORT-LINE
           END-STRING
           WRITE REPORT-LINE

           MOVE WS-TOTAL-WITHDRAW TO WS-AMOUNT-DISP
           MOVE SPACES TO REPORT-LINE
           STRING "TOTAL WITHDRAW AMOUNT:   " WS-AMOUNT-DISP
               DELIMITED BY SIZE INTO REPORT-LINE
           END-STRING
           WRITE REPORT-LINE

           MOVE SPACES TO REPORT-LINE
           WRITE REPORT-LINE FROM "===================================".

       CLOSE-FILES.
           CLOSE ACCT-MASTER
           CLOSE TRANS-FILE
           CLOSE ACCT-NEW
           CLOSE REPORT-FILE
           CLOSE ERROR-FILE.
