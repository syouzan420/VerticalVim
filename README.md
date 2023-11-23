# VerticalVim  
Vimのテキストを縱書きにして 編集します  
コマンド :Ta で縱書きにします  
そのバッファの ノーマルモードで q を押し Enterで決定すると  
縱書きバッファは 破棄されて 元の編集画面にもどります  
縱書きバッファの ノーマルモードで w を押し Enterで決定すると  
編集結果が反映されて 元の横書きバッファに戻ります  

縱書きバッファの ノーマルモードで o を押すと  
横書きの時のやうに 新たな行を挿入します  

このスクリプトは vim9scriptでつくりました  

プラグインマネージャーの [dein](https://github.com/Shougo/dein.vim) を使ふ場合は  
.vimrc に  
call dein#add('syouzan420/VerticalVim')  
を加へてください  
コマンド :call dein#install()  
で インストールできると思ひます
![Screenshot from 2023-11-23 23-13-17](https://github.com/syouzan420/VerticalVim/assets/12661196/cb94acb5-97ab-4fda-8f86-6b2928cecf88)
