# VerticalVim  
Vimのテキストを縱書きにして 編集します  
コマンド :Ta で縱書きにします  
そのバッファの ノーマルモードで q を押し Enterで決定すると  
縱書きバッファは 破棄されて 元の編集画面にもどります  
縱書きバッファの ノーマルモードで w を押し Enterで決定すると  
編集結果が反映されて 元の横書きバッファに戻ります  

縱書きバッファの ノーマルモードで o を押すと  
横書きの時のやうに 新たな行を挿入します  
ノーマルモードでの x キーは まだ完全に機能できてゐません  
一文字消去しますが 挿入モードに移行してしまひます  

このスクリプトは vim9scriptでつくりました  
