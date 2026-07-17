@echo off
chcp 65001 >nul
echo ================================================
echo  AzizArt — Installation COMPLETE
echo ================================================
echo.
SET SRC=%~dp0lib
SET DST=C:\Users\wilcoco\Dev\azizart\lib
SET ERR=0
echo Source : %SRC%
echo Dest   : %DST%
echo.

:: lib\
copy /Y "%SRC%\app.dart" "%DST%\app.dart" >nul && echo [OK] app.dart || (echo [ERR] app.dart & SET ERR=1)
copy /Y "%SRC%\main.dart" "%DST%\main.dart" >nul && echo [OK] main.dart || (echo [ERR] main.dart & SET ERR=1)

:: features\about
if not exist "%DST%\features\about" mkdir "%DST%\features\about"
copy /Y "%SRC%\features\about\about_page.dart" "%DST%\features\about\about_page.dart" >nul && echo [OK] features\about\about_page.dart || (echo [ERR] features\about\about_page.dart & SET ERR=1)

:: features\about\models
if not exist "%DST%\features\about\models" mkdir "%DST%\features\about\models"
copy /Y "%SRC%\features\about\models\about_model.dart" "%DST%\features\about\models\about_model.dart" >nul && echo [OK] features\about\models\about_model.dart || (echo [ERR] features\about\models\about_model.dart & SET ERR=1)

:: features\about\services
if not exist "%DST%\features\about\services" mkdir "%DST%\features\about\services"
copy /Y "%SRC%\features\about\services\about_service.dart" "%DST%\features\about\services\about_service.dart" >nul && echo [OK] features\about\services\about_service.dart || (echo [ERR] features\about\services\about_service.dart & SET ERR=1)

:: features\atelier
if not exist "%DST%\features\atelier" mkdir "%DST%\features\atelier"
copy /Y "%SRC%\features\atelier\atelier_page.dart" "%DST%\features\atelier\atelier_page.dart" >nul && echo [OK] features\atelier\atelier_page.dart || (echo [ERR] features\atelier\atelier_page.dart & SET ERR=1)

:: features\atelier\models
if not exist "%DST%\features\atelier\models" mkdir "%DST%\features\atelier\models"
copy /Y "%SRC%\features\atelier\models\atelier_model.dart" "%DST%\features\atelier\models\atelier_model.dart" >nul && echo [OK] features\atelier\models\atelier_model.dart || (echo [ERR] features\atelier\models\atelier_model.dart & SET ERR=1)

:: features\atelier\services
if not exist "%DST%\features\atelier\services" mkdir "%DST%\features\atelier\services"
copy /Y "%SRC%\features\atelier\services\atelier_service.dart" "%DST%\features\atelier\services\atelier_service.dart" >nul && echo [OK] features\atelier\services\atelier_service.dart || (echo [ERR] features\atelier\services\atelier_service.dart & SET ERR=1)

:: features\atelier\widgets
if not exist "%DST%\features\atelier\widgets" mkdir "%DST%\features\atelier\widgets"
copy /Y "%SRC%\features\atelier\widgets\atelier_photo_grid.dart" "%DST%\features\atelier\widgets\atelier_photo_grid.dart" >nul && echo [OK] features\atelier\widgets\atelier_photo_grid.dart || (echo [ERR] features\atelier\widgets\atelier_photo_grid.dart & SET ERR=1)

:: features\contact
if not exist "%DST%\features\contact" mkdir "%DST%\features\contact"
copy /Y "%SRC%\features\contact\contact_page.dart" "%DST%\features\contact\contact_page.dart" >nul && echo [OK] features\contact\contact_page.dart || (echo [ERR] features\contact\contact_page.dart & SET ERR=1)

:: features\contact\models
if not exist "%DST%\features\contact\models" mkdir "%DST%\features\contact\models"
copy /Y "%SRC%\features\contact\models\contact_model.dart" "%DST%\features\contact\models\contact_model.dart" >nul && echo [OK] features\contact\models\contact_model.dart || (echo [ERR] features\contact\models\contact_model.dart & SET ERR=1)

:: features\contact\services
if not exist "%DST%\features\contact\services" mkdir "%DST%\features\contact\services"
copy /Y "%SRC%\features\contact\services\contact_service.dart" "%DST%\features\contact\services\contact_service.dart" >nul && echo [OK] features\contact\services\contact_service.dart || (echo [ERR] features\contact\services\contact_service.dart & SET ERR=1)

:: features\gallery
if not exist "%DST%\features\gallery" mkdir "%DST%\features\gallery"
copy /Y "%SRC%\features\gallery\gallery_page.dart" "%DST%\features\gallery\gallery_page.dart" >nul && echo [OK] features\gallery\gallery_page.dart || (echo [ERR] features\gallery\gallery_page.dart & SET ERR=1)

:: features\gallery\models
if not exist "%DST%\features\gallery\models" mkdir "%DST%\features\gallery\models"
copy /Y "%SRC%\features\gallery\models\artwork.dart" "%DST%\features\gallery\models\artwork.dart" >nul && echo [OK] features\gallery\models\artwork.dart || (echo [ERR] features\gallery\models\artwork.dart & SET ERR=1)

:: features\gallery\services
if not exist "%DST%\features\gallery\services" mkdir "%DST%\features\gallery\services"
copy /Y "%SRC%\features\gallery\services\gallery_service.dart" "%DST%\features\gallery\services\gallery_service.dart" >nul && echo [OK] features\gallery\services\gallery_service.dart || (echo [ERR] features\gallery\services\gallery_service.dart & SET ERR=1)

:: features\l10n
if not exist "%DST%\features\l10n" mkdir "%DST%\features\l10n"
copy /Y "%SRC%\features\l10n\translations.dart" "%DST%\features\l10n\translations.dart" >nul && echo [OK] features\l10n\translations.dart || (echo [ERR] features\l10n\translations.dart & SET ERR=1)

:: features\loading
if not exist "%DST%\features\loading" mkdir "%DST%\features\loading"
copy /Y "%SRC%\features\loading\loading_screen.dart" "%DST%\features\loading\loading_screen.dart" >nul && echo [OK] features\loading\loading_screen.dart || (echo [ERR] features\loading\loading_screen.dart & SET ERR=1)

:: features\media
if not exist "%DST%\features\media" mkdir "%DST%\features\media"
copy /Y "%SRC%\features\media\media_page.dart" "%DST%\features\media\media_page.dart" >nul && echo [OK] features\media\media_page.dart || (echo [ERR] features\media\media_page.dart & SET ERR=1)

:: features\media\models
if not exist "%DST%\features\media\models" mkdir "%DST%\features\media\models"
copy /Y "%SRC%\features\media\models\media_model.dart" "%DST%\features\media\models\media_model.dart" >nul && echo [OK] features\media\models\media_model.dart || (echo [ERR] features\media\models\media_model.dart & SET ERR=1)

:: features\media\services
if not exist "%DST%\features\media\services" mkdir "%DST%\features\media\services"
copy /Y "%SRC%\features\media\services\media_service.dart" "%DST%\features\media\services\media_service.dart" >nul && echo [OK] features\media\services\media_service.dart || (echo [ERR] features\media\services\media_service.dart & SET ERR=1)

:: features\media\widgets
if not exist "%DST%\features\media\widgets" mkdir "%DST%\features\media\widgets"
copy /Y "%SRC%\features\media\widgets\media_card.dart" "%DST%\features\media\widgets\media_card.dart" >nul && echo [OK] features\media\widgets\media_card.dart || (echo [ERR] features\media\widgets\media_card.dart & SET ERR=1)

:: features\models
if not exist "%DST%\features\models" mkdir "%DST%\features\models"
copy /Y "%SRC%\features\models\artwork.dart" "%DST%\features\models\artwork.dart" >nul && echo [OK] features\models\artwork.dart || (echo [ERR] features\models\artwork.dart & SET ERR=1)
copy /Y "%SRC%\features\models\atelier_model.dart" "%DST%\features\models\atelier_model.dart" >nul && echo [OK] features\models\atelier_model.dart || (echo [ERR] features\models\atelier_model.dart & SET ERR=1)
copy /Y "%SRC%\features\models\media_model.dart" "%DST%\features\models\media_model.dart" >nul && echo [OK] features\models\media_model.dart || (echo [ERR] features\models\media_model.dart & SET ERR=1)

:: features\services
if not exist "%DST%\features\services" mkdir "%DST%\features\services"
copy /Y "%SRC%\features\services\locale_service.dart" "%DST%\features\services\locale_service.dart" >nul && echo [OK] features\services\locale_service.dart || (echo [ERR] features\services\locale_service.dart & SET ERR=1)

:: features\theme
if not exist "%DST%\features\theme" mkdir "%DST%\features\theme"
copy /Y "%SRC%\features\theme\aziz_colors.dart" "%DST%\features\theme\aziz_colors.dart" >nul && echo [OK] features\theme\aziz_colors.dart || (echo [ERR] features\theme\aziz_colors.dart & SET ERR=1)

:: l10n
if not exist "%DST%\l10n" mkdir "%DST%\l10n"
copy /Y "%SRC%\l10n\locale_service.dart" "%DST%\l10n\locale_service.dart" >nul && echo [OK] l10n\locale_service.dart || (echo [ERR] l10n\locale_service.dart & SET ERR=1)
copy /Y "%SRC%\l10n\translations.dart" "%DST%\l10n\translations.dart" >nul && echo [OK] l10n\translations.dart || (echo [ERR] l10n\translations.dart & SET ERR=1)

:: models
if not exist "%DST%\models" mkdir "%DST%\models"
copy /Y "%SRC%\models\artwork.dart" "%DST%\models\artwork.dart" >nul && echo [OK] models\artwork.dart || (echo [ERR] models\artwork.dart & SET ERR=1)
copy /Y "%SRC%\models\atelier_model.dart" "%DST%\models\atelier_model.dart" >nul && echo [OK] models\atelier_model.dart || (echo [ERR] models\atelier_model.dart & SET ERR=1)
copy /Y "%SRC%\models\media_model.dart" "%DST%\models\media_model.dart" >nul && echo [OK] models\media_model.dart || (echo [ERR] models\media_model.dart & SET ERR=1)

:: services
if not exist "%DST%\services" mkdir "%DST%\services"
copy /Y "%SRC%\services\cache_service.dart" "%DST%\services\cache_service.dart" >nul && echo [OK] services\cache_service.dart || (echo [ERR] services\cache_service.dart & SET ERR=1)
copy /Y "%SRC%\services\locale_service.dart" "%DST%\services\locale_service.dart" >nul && echo [OK] services\locale_service.dart || (echo [ERR] services\locale_service.dart & SET ERR=1)

:: theme
if not exist "%DST%\theme" mkdir "%DST%\theme"
copy /Y "%SRC%\theme\app_theme.dart" "%DST%\theme\app_theme.dart" >nul && echo [OK] theme\app_theme.dart || (echo [ERR] theme\app_theme.dart & SET ERR=1)
copy /Y "%SRC%\theme\aziz_colors.dart" "%DST%\theme\aziz_colors.dart" >nul && echo [OK] theme\aziz_colors.dart || (echo [ERR] theme\aziz_colors.dart & SET ERR=1)

:: utils
if not exist "%DST%\utils" mkdir "%DST%\utils"
copy /Y "%SRC%\utils\responsive.dart" "%DST%\utils\responsive.dart" >nul && echo [OK] utils\responsive.dart || (echo [ERR] utils\responsive.dart & SET ERR=1)

:: widgets
if not exist "%DST%\widgets" mkdir "%DST%\widgets"
copy /Y "%SRC%\widgets\artwork_card.dart" "%DST%\widgets\artwork_card.dart" >nul && echo [OK] widgets\artwork_card.dart || (echo [ERR] widgets\artwork_card.dart & SET ERR=1)
copy /Y "%SRC%\widgets\diamond_divider.dart" "%DST%\widgets\diamond_divider.dart" >nul && echo [OK] widgets\diamond_divider.dart || (echo [ERR] widgets\diamond_divider.dart & SET ERR=1)
copy /Y "%SRC%\widgets\language_picker.dart" "%DST%\widgets\language_picker.dart" >nul && echo [OK] widgets\language_picker.dart || (echo [ERR] widgets\language_picker.dart & SET ERR=1)
copy /Y "%SRC%\widgets\navbar.dart" "%DST%\widgets\navbar.dart" >nul && echo [OK] widgets\navbar.dart || (echo [ERR] widgets\navbar.dart & SET ERR=1)

echo.
if %ERR%==1 (echo Certains fichiers ont echoue) else (echo Tous les fichiers OK)
echo 40 fichiers traites.
echo.
echo Executez maintenant: flutter analyze
echo ================================================
pause