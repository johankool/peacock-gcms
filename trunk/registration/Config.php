<?php
/** 
  * AquaticPrime PHP Config
  * Configuration for web server license generation
  * @author Lucas Newman, Aquatic
  * @copyright Copyright &copy; 2005 Lucas Newman
  * @license http://www.opensource.org/licenses/bsd-license.php BSD License
  */

// ----CONFIG----

// When pasting keys here, don't include the leading "0x" that AquaticPrime Developer adds.
$key = "EF530061CFA7A61077F5717FBA331217BE381522A818106B478073B873C8C1581BC4C5E2133FC4A8ED3402ACC611817443255378912C60D99B1C8190F63E6DE9E21AAFD6BF6B72DFDCF898D9F22CD80FAE92AC1440294FD3DFD3C0A31A6937ACB14B9A744ACCCB34C8DC54876C02F8D819D3511C45F935B431410D793F34D945";
$privateKey = "9F8CAAEBDFC519604FF8F65526CCB6BA7ED00E171ABAB59CDA55A27AF7DB2B9012832E96B77FD8709E22AC732EB6564D8218E25060C840911213010B4ED449454CB0DBE98E48813FF72EF8EF41B7526BEE92B7A320A61A87BE4F3D96FDE45BD51056690BD8C2506FED76E8CC618B47A0DE61302901987C86E09E1E86B95053F3";

$domain = "johankool.nl";
$product = "Peacock";
$version = "0.23";
$download = "http://peacock.$domain/";

// These fields below should be customized for your application.  You can use ##NAME## in place of the customer's name and ##EMAIL## in place of his/her email
$from = "registrations@$domain";
$subject = "$product License For ##NAME##";
$message =
"Hello ##NAME##,

Thank you for registering! Attached to this e-mail is your license for $product.

If you have not already downloaded $product please do so now from:
<$download>

Drag the attached file onto Peacock's icon to register $product. Alternatively you can double-click the file to open it.

Thanks,

Johan Kool

---
Registration details:
Name: ##NAME##
E-mail: ##EMAIL##
Country: ##COUNTRY## (if provided)
Institution Type: ##TYPE## (if provided)
System Information: ##INFORMATION## (if provided)

---
Peacock
- Proudly presenting the peaks... -

http://peacock.johankool.nl/
";

// It's a good idea to BCC your own email here so you can have an order history
$bcc = "registrations@$domain";

// This is the name of the license file that will be attached to the email
$licenseName = "##NAME##.peacock-license";

?>
