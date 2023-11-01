# ICLab 2021 Spring

ICLab ist ein bekannter Aufgabensatz für Studenten in der Vertiefungsrichtung Digital ASIC Design, der von der National Yang Ming Chiao Tung University zur Verfügung gestellt wird.

Wegen der fehlenden EDA-Tools werden die Designs in diesem Repository mit Xilinx Vivado erstellt und simuliert.

### Lab01
Das Ziel dieses Moduls ist der Entwurf eines MOSFET-Rechners. Nur kombinatorische Schaltungen sind erlaubt.

Die Eingänge bestehen aus 6 Datensätzen, von denen jeder die Kanalbreite, V_GS und V_DS enthält.
Zusätzlich wird ein 2-Bit-Modussignal gegeben, das die Art der Sortierung und den zu berechnenden Wert angibt.

Zunächst muss der Modus des MOSFETs bestimmt werden, entweder im Trioden- oder Sättigungsbereich. Anschließend wird mithilfe des Modussignals die Transkonduktanz oder der Strom berechnet. Schließlich müssen entweder die drei größten oder die drei kleinsten Werte addiert und als Output ausgegeben werden.


### Lab02
Dieses Modul erkennt bei einer Zeichenkette und einem Muster, ob das Muster in der Zeichenkette enthalten ist oder nicht.

### Lab03
Dieses Modul löst ein 9x9 Sudoku-Gitter mit 15 leeren Positionen. Es muss auch erkannt werden, ob das gegebene Spiel lösbar ist oder nicht.

### Lab04
Ziel ist es, einen ANN-Beschleuniger mit drei Schichten zu bauen, der einen Backpropagation-Algorithmus zur Lösung eines Regressionsproblems verwendet.
Das Floating-Point IP mit AXI4-Lite von Xilinx Vivado wird verwendet.

### Lab08
Vier Operationen werden durchgeführt (modulare Inversion / modulare Multiplikation / Sortierung / Summierung) basierend auf den verschiedenen Modussignalen.
Zwei Versionen sind enthalten: eine mit Clock-Gating und eine ohne. 
