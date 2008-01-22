<?php
/** 
  * AquaticPrime Form Only processor
  * Generates license files and emails them using a form (NO payment!)
  * @author Lucas Newman, Aquatic
  * @author Johan Kool
  * @copyright Copyright &copy; 2005 Lucas Newman, 2008 Johan Kool
  * @license http://www.opensource.org/licenses/bsd-license.php BSD License
  */

require("Config.php");
require("AquaticPrime.php");

$name = $_POST["name"];
$email = $_POST["email"];
$country = $_POST["country"];
$type = $_POST["type"];
$information = $_POST["information"];

if (!isset($_POST['submit'])) { // if page is not submitted to itself echo the form
?>
    <html>
    <head>
    <title><?php echo $product;?> Registration Form</title>
    </head>
    <body>
    <h1><?php echo $product;?> Registration Form</h1>
    <p>Please supply your name and e-mailaddress to register <?php echo $product;?>. You will receive your license by mail. Fields marked with an asterisk (*) are required.</p>
    <p><form method="post" action="<?php echo $PHP_SELF;?>">
    <table border="0" cellspacing="0" cellpadding="5">   
    <tr><td align="right"><label for="name">Full Name:</label></td><td><input type="text" name="name" value="" id="name"> *</td></tr>
    <tr><td align="right"><label for="email">E-mail:</label></td><td><input type="text" name="email" value="" id="email"> *</td></tr>
    <tr><td align="right"><label for="country">Country:</label></td><td><input type="text" name="country" value="" id="country"></td></tr>
    <tr><td align="right"><label for="type">Institution Type:</label></td><td><select name="type" id="type" single onchange="" size="1">
        <option value="">Please Select</option>
        <option value="Academic">Academic</option>
        <option value="Research">Research</option>
        <option value="Commercial">Commercial</option>
        <option value="Personal">Personal</option>
        <option value="Other">Other</option>        
    </select></td></tr>
    <tr><td> </td><td align="right"><input type="submit" value="Register" name="submit">
    </table>
    </form></p>
    </body>
<? 
} else {
    // take a given email address and split it into the username and domain. 
    list($userName, $mailDomain) = split("@", $email); 
    if (!checkdnsrr($mailDomain, "MX")) { 
        // this email domain doesn't exist!
        ?>
        <html>
        <head>
        <title>Error</title>
        </head>
        <body>
        <h1>Not a valid mail address.</h1>
        <p>Please supply a valid mail address to receive the license.</p>
        </body>
        <?
    } else { 
        // this is a valid email domain! 
        $count = 1;
        // RFC 2822 formatted date
        $timestamp = strftime("%Y-%m-%d %H:%m:%S");
        $transactionID = "-";

        // Create our license dictionary to be signed
        $dict = array("Product" => $product,
                   "Name" => $name,
                   "Email" => $email,
                   "Licenses" => $count,
                   "Timestamp" => $timestamp,
                   "Version" => $version,
                   "Type" => "User");

        $license = licenseDataForDictionary($dict, $key, $privateKey);

        $to = $email;

        $from = str_replace(array("##NAME##", "##EMAIL##", "##COUNTRY##", "##TYPE##", "##INFORMATION##"), array($name, $email, $country, $type, $information), $from);
        $subject = str_replace(array("##NAME##", "##EMAIL##", "##COUNTRY##", "##TYPE##", "##INFORMATION##"), array($name, $email, $country, $type, $information), $subject);
        $message = str_replace(array("##NAME##", "##EMAIL##", "##COUNTRY##", "##TYPE##", "##INFORMATION##"), array($name, $email, $country, $type, $information), $message);
        $licenseName = str_replace(array("##NAME##", "##EMAIL##", "##COUNTRY##", "##TYPE##", "##INFORMATION##"), array($name, $email, $country, $type, $information), $licenseName);
        $bcc = str_replace(array("##NAME##", "##EMAIL##", "##COUNTRY##", "##TYPE##", "##INFORMATION##"), array($name, $email, $country, $type, $information), $bcc);

        sendMail($to, $from, $subject, $message, $license, $licenseName, $bcc);
        // let the user know the license is on its way
            ?>
            <html>
            <head>
            <title>Thank you</title>
            </head>
            <body>
            <h1>Thank you for registering <?php echo $product;?>!</h1>
            <p>You will receive your license by e-mail shortly. The mail is sent from <?php echo $from;?>.</p>
            </body>
        <?
    }
}
?>
