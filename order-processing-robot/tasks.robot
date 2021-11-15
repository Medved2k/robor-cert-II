*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Collections
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           OperatingSystem


*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order

${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv

*** Test Cases ***
Order robots from RobotSpareBin Industries Inc
    [Setup]  Directory Cleanup
    [Teardown]     Log Out And Close The Browser

    Get Path to vault
    Read some data from the ${local_vault}
    


    Open the robot order website

    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form           ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${pdf}=                Store the receipt as a PDF file  ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot  ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file     ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

    

*** Keywords ***
Directory Cleanup
    Log To console      Cleaning up content from previous test runs

    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

    Empty Directory     ${img_folder}
    Empty Directory     ${pdf_folder}
    
Open the robot order website
    Open Available Browser     ${url}
  
Get orders
    Download    url=${csv_url}         target_file=${orders_file}    overwrite=True
    ${table}=   Read table from CSV    path=${orders_file}
    [Return]  ${table}

Close the annoying modal
    Set Local Variable              ${btn_yep}        //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button           ${btn_yep}

Fill the form
    [Arguments]     ${row}

    Set Local Variable    ${order_no}   ${row}[Order number]

    Set Local Variable      ${head}       //*[@id="head"]
    Set Local Variable      ${body}       body
    Set Local Variable      ${legs}       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable      ${address}    //*[@id="address"]
    Set Local Variable      ${btn_preview}      //*[@id="preview"]
    Set Local Variable      ${btn_order}        //*[@id="order"]
    Set Local Variable      ${img_preview}      //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${head}

    Wait Until Element Is Enabled   ${head}
    Select From List By Value       ${head}           ${row}[Head]

    Wait Until Element Is Enabled   ${body}
    Select Radio Button             ${body}           ${row}[Body]

    Wait Until Element Is Enabled   ${legs}
    Input Text                      ${legs}           ${row}[Legs]

    Wait Until Element Is Enabled   ${address}
    Input Text                      ${address}        ${row}[Address]

Preview the robot
    Set Local Variable              ${btn_preview}      //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]

    Click Button                    ${btn_preview}
    Wait Until Element Is Visible   ${img_preview}

Submit the order
    Set Local Variable              ${btn_order}        //*[@id="order"]
    Set Local Variable              ${lbl_receipt}      //*[@id="receipt"]

    Mute Run On Failure             Page Should Contain Element 

    Click button                    ${btn_order}
    Page Should Contain Element     ${lbl_receipt}

Take a screenshot of the robot
    [Arguments]    ${order}
    Set Local Variable      ${lbl_orderid}      xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable      ${img_robot}        //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   ${lbl_orderid} 

    Set Local Variable              ${fully_qualified_img_filename}    ${img_folder}${/}${order}.png

    Sleep   1sec
    Capture Element Screenshot      ${img_robot}    ${fully_qualified_img_filename}
    
    [Return]    ${fully_qualified_img_filename}

Go to order another robot
    Set Local Variable      ${btn_order_another_robot}      //*[@id="order-another"]
    Click Button            ${btn_order_another_robot}

Log Out And Close The Browser
    Close Browser

Create a Zip File of the Receipts
    Archive Folder With ZIP     ${pdf_folder}  ${zip_file}   recursive=True  include=*.pdf

Store the receipt as a PDF file
    [Arguments]        ${order}

    Wait Until Element Is Visible   //*[@id="receipt"]
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${order}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}     ${PDF}

    Log To Console                  Printing Embedding image ${screenshot} in pdf file ${PDF}
    Open PDF        ${PDF}
    @{myfiles}=       Create List     ${screenshot}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF}     ${True}
    Close PDF           ${PDF}

Get Path to vault
    Add heading             Enter path to the vault
    Add text input          vault_path    label=Where is your vault?     placeholder=Hint ../order-processing-robot/vault.json
    ${result}=              Run dialog
    Set Test Variable    ${local_vault}  ${result.vault_path}
    
Read some data from the ${vault}
    Log To Console          Getting Secret from the ${vault} 
    ${secret}=              Get Secret      data
    Log                     The author ${secret}[author] done this at ${secret}[cur_date]     console=yes
    
    

