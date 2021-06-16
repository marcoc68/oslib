/ /   M Q L 4 & 5 - c o d e  
  
 / /   P a r a l l e l   u s e   o f   t h e   M e t a T r a d e r   4   a n d   M e t a T r a d e r   5   o r d e r   s y s t e m s .  
 / /   h t t p s : / / w w w . m q l 5 . c o m / e n / c o d e / 1 6 0 0 6  
  
 / /   T h i s   m q h   f i l e   a l l o w s   w o r k i n g   w i t h   t h e   o r d e r s   i n   M Q L 5   ( M T 5 - h e d g e )   i n   t h e   s a m e   w a y   a s   i n   M Q L 4 .  
 / /   T h a t   i s ,   t h e   o r d e r   l a n g u a g e   s y s t e m   ( O L S )   b e c o m e s   i d e n t i c a l   t o   M Q L 4 .   / /   A t   t h e   s a m e   t i m e ,   i t   i s   s t i l l   p o s s i b l e   t o   u s e  
 / /   t h e   M Q L 5   o r d e r   s y s t e m   i n   p a r a l l e l .   I n   p a r t i c u l a r ,   t h e   s t a n d a r d   M Q L 5   l i b r a r y   w i l l   c o n t i n u e   t o   f u l l y   o p e r a t e .  
 / /   I t   i s   n o t   n e c e s s a r y   t o   c h o o s e   b e t w e e n   t h e   o r d e r   s y s t e m s .   U s e   t h e m   i n   p a r a l l e l !  
  
 / /   W h e n   t r a n s l a t i n g   M Q L 4   - >   M Q L 5 ,   t h e r e   i s   n o   n e e d   t o   t o u c h   t h e   o r d e r   s y s t e m   a t   a l l .  
 / /   I t   i s   s u f f i c i e n t   t o   a d d   a   s i n g l e   l i n e   a t   t h e   b e g i n n i n g   ( i f   t h e   s o u r c e   f i l e   c a n   c o m p i l e   i n   M e t a T r a d e r   4   w i t h   # p r o p e r t y   s t r i c t ) :  
  
 / /   # i n c l u d e   < M T 4 O r d e r s . m q h >   / /   i f   t h e r e   i s   # i n c l u d e   < E x p e r t / E x p e r t . m q h > ,   a d d   t h i s   l i n e   A F T E R   t h a t  
  
 / /   S i m i l a r   a c t i o n s   ( a d d i n g   o n e   l i n e )   i n   y o u r   M Q L 5   c o d e s   a l l o w   t o   a d d   t h e   M T 4   O L S   t o   t h e   M T 5   O L S ,   o r   c o m p l e t e l y   r e p l a c e   i t .  
  
 / /   T h e   a u t h o r   h a d   c r e a t e d   t h i s   f e a t u r e   f o r   h i m s e l f ,   t h e r e f o r e ,   h e   d e l i b e r a t e l y   h a d   n o t   a p p l i e d   t h e   s a m e   i d e a   o f   " o n e - l i n e "   t r a n s f e r  
 / /   f o r   t i m e s e r i e s ,   g r a p h i c a l   o b j e c t s ,   i n d i c a t o r s ,   e t c .  
  
 / /   T h i s   w o r k   c o v e r s   o n l y   t h e   o r d e r   s y s t e m .  
  
 / /   T h e   t a s k   o f   p o s s i b i l i t y   t o   c r e a t e   a   c o m p l e t e   l i b r a r y   f o r   a l l o w i n g   t h e   M Q L 4   c o d e   t o   w o r k   i n   M e t a T r a d e r   5   w i t h o u t   c h a n g e s   h a d   n o t   b e e n   c o n s i d e r e d .  
  
 / /   W h a t   i s   n o t   i m p l e m e n t e d :  
 / /       C l o s e B y   o p e r a t i o n s   -   d i d   n o t   h a v e   t i m e   f o r   t h a t .   M a y b e   i n   t h e   f u t u r e ,   w h e n   i t   i s   n e e d e d .  
 / /       D e t e c t i o n   o f   T P   a n d   S L   o f   c l o s e d   p o s i t i o n   -   a s   o f   n o w   ( b u i l d   1 4 7 0 ) ,   M Q L 5   i s   u n a b l e   t o   d o   t h a t .  
 / /       A c c o u n t i n g   o f   D E A L _ E N T R Y _ I N O U T   a n d   D E A L _ E N T R Y _ O U T _ B Y   d e a l s .  
  
 / /   F e a t u r e s :  
 / /       I n   M e t a T r a d e r   4 ,   O r d e r S e l e c t   i n   t h e   S E L E C T _ B Y _ T I C K E T   m o d e   s e l e c t s   a   t i c k e t   r e g a r d l e s s   o f   M O D E _ T R A D E S / M O D E _ H I S T O R Y ,  
 / /       b e c a u s e   " T h e   t i c k e t   n u m b e r   i s   a   u n i q u e   o r d e r   i d e n t i f i e r " .  
 / /       I n   M e t a T r a d e r   5 ,   t h e   t i c k e t   n u m b e r   i s   N O T   u n i q u e ,  
 / /       t h e r e f o r e ,   O r d e r S e l e c t   i n   t h e   S E L E C T _ B Y _ T I C K E T   m o d e   h a s   t h e   f o l l o w i n g   s e l e c t i o n   p r i o r i t i e s   f o r   m a t c h i n g   t i c k e t s :  
 / /           M O D E _ T R A D E S :     e x i s t i n g   p o s i t i o n   >   e x i s t i n g   o r d e r   >   d e a l   >   c a n c e l e d   o r d e r  
 / /           M O D E _ H I S T O R Y :   d e a l   >   c a n c e l e d   o r d e r   >   e x i s t i n g   p o s i t i o n   >   e x i s t i n g   o r d e r  
 / /  
 / /   A c c o r d i n g l y ,   O r d e r S e l e c t   i n   t h e   S E L E C T _ B Y _ T I C K E T   m o d e   i n   M e t a T r a d e r   5   m a y   o c c a s i o n a l l y   ( i n   t h e   t e s t e r )   s e l e c t   n o t   w h a t   w a s   i n t e n d e d   i n   M e t a T r a d e r   4 .  
 / /  
 / /   I f   O r d e r s T o t a l ( )   i s   c a l l e d   w i t h   a n   i n p u t   p a r a m e t e r ,   t h e   r e t u r n e d   v a l u e   w i l l   n o t   c o r r e s p o n d   t o   t h e   M e t a T r a d e r   5   v a r i a n t .  
  
 / /   L i s t   o f   c h a n g e s :  
 / /   0 3 / 0 8 / 2 0 1 6 :  
 / /       R e l e a s e   -   w r i t t e n   a n d   t e s t e d   o n l y   o n   t h e   o f f l i n e   t e s t e r .  
 / /   2 9 / 0 9 / 2 0 1 6 :  
 / /       A d d :   s u p p o r t   f o r   o p e r a t i o n   o n   e x c h a n g e s   ( S Y M B O L _ T R A D E _ E X E C U T I O N _ E X C H A N G E ) .   N o t e   t h a t   e x c h a n g e s   u s e   N e t t i n g   ( n o t   H e d g i n g )   m o d e .  
 / /       A d d :   R e q u i r e m e n t   " i f   t h e r e   i s   # i n c l u d e   < T r a d e / T r a d e . m q h > ,   i n s e r t   t h i s   l i n e   A F T E R "  
 / /                 c h a n g e d   t o   " i f   t h e r e   i s   # i n c l u d e   < E x p e r t / E x p e r t . m q h > ,   i n s e r t   t h i s   l i n e   A F T E R " .  
 / /       F i x :   O r d e r S e n d   f o r   m a r k e t   o r d e r s   r e t u r n s   p o s i t i o n   t i c k e t ,   n o t   d e a l   t i c k e t .  
 / /   1 3 / 1 1 / 2 0 1 6 :  
 / /       A d d :   C o m p l e t e   s y n c h r o n i z a t i o n   o f   O r d e r S e n d ,   O r d e r M o d i f y ,   O r d e r C l o s e ,   O r d e r D e l e t e   A  B>@3>2K<  >:@C65=85<  ( @50;- B09<  8  8AB>@8O)   -   w i t h   t h e   t r a d i n g   e n v i r o n m e n t   ( r e a l - t i m e   a n d   h i s t o r y )   -   a s   i n   M e t a T r a d e r   4 .  
 / /                 T h e   m a x i m u m   s y n c h r o n i z a t i o n   t i m e   c a n   b e   s e t   u s i n g   M T 4 O R D E R S   : :   O r d e r S e n d _ M a x P a u s e   i n   m i c r o s e c o n d s .   T h e   a v e r a g e   s y n c h r o n i z a t i o n   t i m e   i n   M e t a T r a d e r   5   i s   ~   1   m i c r o s e c o n d .  
 / /                 B y   d e f a u l t ,   t h e   m a x i m u m   s y n c h r o n i z a t i o n   t i m e   i s   o n e   s e c o n d .   M T 4 O R D E R S : : O r d e r S e n d _ M a x P a u s e   =   0   -   n o   s y n c h r o n i z a t i o n .  
 / /       A d d :   S i n c e   t h e   p a r a m e t e r   S l i p P a g e   ( O r d e r S e n d ,   O r d e r C l o s e )   a f f e c t s   t h e   e x e c u t i o n   o f   m a r k e t   o r d e r s   o n l y   i n   I n s t a n t   m o d e ,  
 / /                 i t   c a n   n o w   b e   u s e d   t o   s e t   t h e   t y p e   o f   e x e c u t i o n   b y   r e m a i n d e r ,   i f   n e c e s s a r y   -   E N U M _ O R D E R _ T Y P E _ F I L L I N G :  
 / /                 O R D E R _ F I L L I N G _ F O K ,   O R D E R _ F I L L I N G _ I O C   o r   O R D E R _ F I L L I N G _ R E T U R N .  
 / /                 I n   c a s e   i t   i s   s e t   b y   m i s t a k e ,   o r   i f   t h e   s y m b o l   d o e s   n o t   s u p p o r t   t h e   s p e c i f i e d   e x e c u t i o n   t i m e ,   t h e   w o r k i n g   m o d e   w i l l   b e   a u t o m a t i c a l l y   s e l e c t e d .  
 / /                 E x a m p l e s :  
 / /                     O r d e r S e n d ( S y m b ,   T y p e ,   L o t s ,   P r i c e ,   O R D E R _ F I L L I N G _ F O K ,   S L ,   T P )   -   s e n d   t h e   c o r r e s p o n d i n g   o r d e r   w i t h   t h e   e x e c u t i o n   t y p e   O R D E R _ F I L L I N G _ F O K  
 / /                     O r d e r S e n d ( S y m b ,   T y p e ,   L o t s ,   P r i c e ,   O R D E R _ F I L L I N G _ I O C ,   S L ,   T P )   -   s e n d   t h e   c o r r e s p o n d i n g   o r d e r   w i t h   t h e   e x e c u t i o n   t y p e   O R D E R _ F I L L I N G _ I O C  
 / /                     O r d e r C l o s e ( T i c k e t ,   L o t s ,   P r i c e ,   O R D E R _ F I L L I N G _ R E T U R N )   -   s e n d   t h e   c o r r e s p o n d i n g   o r d e r   w i t h   t h e   e x e c u t i o n   t y p e   O R D E R _ F I L L I N G _ R E T U R N  
 / /       A d d :   O r d e r s H i s t o r y T o t a l ( )   a n d   O r d e r S e l e c t ( P o s ,   S E L E C T _ B Y _ P O S ,   M O D E _ H I S T O R Y )   a r e   c a c h e d   -   t h e y   w o r k   a s   f a s t   a s   p o s s i b l e .  
 / /                 T h e r e   a r e   n o   m o r e   s l o w   i m p l e m e n t a t i o n s   i n   t h e   l i b r a r y .  
 / /   0 8 / 0 2 / 2 0 1 7 :  
 / /       A d d :   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t   a n d   M T 4 O R D E R S : : L a s t T r a d e R e s u l t   v a r i a b l e s   c o n t a i n   t h e   c o r r e s p o n d i n g   M T 5 - O r d e r S e n d   d a t a .  
 / /   1 4 / 0 6 / 2 0 1 7 :  
 / /       A d d :   I m p l e m e n t e d   t h e   i n i t i a l l y   b u i l t - i n   d e t e c t i o n   o f   S L / T P   o f   p o s i t i o n s   c l o s e d   u s i n g   O r d e r C l o s e .  
 / /       A d d :   M a g i c N u m b e r   n o w   h a s   t h e   l o n g   t y p e   -   8   b y t e s   ( w h i l e   i t   w a s   i n t   -   4   b y t e s   p r e v i o u s l y ) .  
 / /       A d d :   I f   t h e   l a s t   c o l o r   i n p u t   p a r a m e t e r   i n   O r d e r S e n d ,   O r d e r C l o s e   o r   O r d e r M o d i f y   i s   s e t   t o   I N T _ M A X ,  
 / /                 t h e   a p p r o p r i a t e   M T 5   t r a d e   r e q u e s t   ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t )   i s   f o r m e d   b u t   N O T   s e n t .   M T 5   c h e c k   i s   c a r r i e d   o u t   i n s t e a d ,  
 / /                 a n d   i t s   r e s u l t   b e c o m e s   a v a i l a b l e   i n   M T 4 O R D E R S : : L a s t T r a d e C h e c k R e s u l t .  
 / /                 I n   c a s e   o f   a   s u c c e s s f u l   c h e c k ,   O r d e r M o d i f y   a n d   O r d e r C l o s e   r e t u r n   t r u e ,   o t h e r w i s e   -   f a l s e .  
 / /                 O r d e r S e n d   r e t u r n s   0   i f   s u c c e s s f u l ,   o t h e r w i s e   -   - 1 .  
 / /  
 / /                 I f   t h e   c o r r e s p o n d i n g   c o l o r   i n p u t   p a r a m e t e r   i s   s e t   t o   I N T _ M I N ,   i t   i s   s e n t   O N L Y   i n   c a s e   o f   a   s u c c e s s f u l   M T 5   c h e c k   o f   t h e   f o r m e d  
 / /                 t r a d e   r e q u e s t   ( a s   I N T _ M A X ) .  
 / /       A d d :   A d d e d   a s y n c h r o n o u s   e q u i v a l e n t s   o f   M Q L 4   t r a d e   f u n c t i o n s :   O r d e r S e n d A s y n c ,   O r d e r M o d i f y A s y n c ,   O r d e r C l o s e A s y n c ,   O r d e r D e l e t e A s y n c .  
 / /                 T h e y   r e t u r n   t h e   a p p r o p r i a t e   R e s u l t . r e q u e s t _ i d   i f   s u c c e s s f u l ,   o t h e r w i s e   -   0 .  
 / /   0 3 / 0 8 / 2 0 1 7 :  
 / /       A d d :   A d d e d   O r d e r C l o s e B y .  
 / /       A d d :   A c c e l e r a t e d   t h e   o p e r a t i o n   o f   O r d e r S e l e c t   i n   t h e   M O D E _ T R A D E S   m o d e .   N o w ,   t h e   d a t a   o f   a   s e l e c t e d   o r d e r   c a n   b e   o b t a i n e d   v i a  
 / /                 R e l e v a n t   M T 4 - O r d e r   f u n c t i o n s ,   e v e n   i s   t h e   M T 5   p o s i t i o n / o r d e r   ( n o t   i n   h i s t o r y )   i s n ' t   s e l e c t e d   v i a   M T 4 O r d e r s .  
 / /                 F o r   e x a m p l e ,   v i a   t h e   M T 5 - P o s i t i o n S e l e c t *   f u n c t i o n s   o r   M T 5 - O r d e r S e l e c t .  
 / /       A d d :   A d d e d   O r d e r O p e n P r i c e R e q u e s t ( )   a n d   O r d e r C l o s e P r i c e R e q u e s t ( )   -   r e t u r n   t h e   t r a d i n g   r e q u e s t   p r i c e   a t   o p e n i n g / c l o s i n g   a   p o s i t i o n .  
 / /                 U s i n g   t h e   d a t a   o f   t h e   f u n c t i o n s ,   y o u   c a n   c o m p u t e   t h e   r e l e v a n t   s l i p p a g e s   o f   t h e   o r d e r s .  
 / /   2 6 / 0 8 / 2 0 1 7 :  
 / /       A d d :   A d d e d   O r d e r O p e n T i m e M s c ( )   a n d   O r d e r C l o s e T i m e M s c ( )   -   r e l e v a n t   t i m e   i n   m i l l i s e c o n d s .  
 / /       F i x :   P r e v i o u s l y ,   a l l   t r a d e   t i c k e t s   w e r e   o f   t y p e   i n t ,   l i k e   i n   M T 4 .   D u e   t o   t h e   o c c u r r e n c e s   o f   g o i n g   b e y o n d   t h e   i n t   t y p e   i n   M T 5 ,   t h e   t y p e   o f   t i c k e t s   i s   c h a n g e d   f o r   l o n g .  
 / /                 A c c o r d i n g l y ,   O r d e r T i c k e t   a n d   O r d e r S e n d   r e t u r n   ' l o n g '   v a l u e s .   M o d e   o f   r e t u r n i n g   t h e   s a m e   t y p e   a s   i n   M T 4   ( i n t ) ,   t o   b e   e n a b l e d   v i a  
 / /                 W r i t i n g   t h e   n e x t   s t r i n g   b e f o r e   # i n c l u d e   < M T 4 O r d e r s . m q h >  
  
 / /                 # d e f i n e   M T 4 _ T I C K E T _ T Y P E   / /   M a k e   O r d e r S e n d   a n d   O r d e r T i c k e t   r e t u r n   a   v a l u e   o f   t h e   s a m e   t y p e   a s   i n   M T 4   ( i n t ) .  
 / /   0 3 / 0 9 / 2 0 1 7 :  
 / /       A d d :   A d d e d   O r d e r T i c k e t O p e n ( )     -   t h e   t i c k e t   o f   t h e   M T 5   t r a n s a c t i o n   o f   o p e n i n g   a   p o s i t i o n  
 / /                                     O r d e r O p e n R e a s o n ( )     -   r e a s o n   f o r   p e r f o r m i n g   t h e   M T 5   t r a n s a c t i o n   o f   o p e n i n g   ( r e a s o n   f o r   o p e n i n g   t h e   p o s i t i o n )  
 / /                                     O r d e r C l o s e R e a s o n ( )   -   r e a s o n   f o r   p e r f o r m i n g   t h e   M T 5   t r a n s a c t i o n   o f   c l o s i n g   ( r e a s o n   f o r   c l o s i n g   t h e   p o s i t i o n )  
 / /   1 4 / 0 9 / 2 0 1 7 :  
 / /       F i x :   N o w   t h e   l i b r a r y   d o e s   n o t   s e e   t h e   c u r r e n t   M T 5   o r d e r s   t h a t   d o   n o t   h a v e   t h e   s t a t e   o f   O R D E R _ S T A T E _ P L A C E D .  
 / /                 F o r   t h e   l i b r a r y   t o   s e e   a l l   t h e   o p e n   M T 5   o r d e r s ,   y o u   s h o u l d   w r i t e   t h e   f o l l o w i n g   s t r i n g   B E F O R E   t h e   l i b r a r y  
 / /  
 / /                 # d e f i n e   M T 4 O R D E R S _ S E L E C T F I L T E R _ O F F   / /   M a k e   M T 4 O r d e r s . m q h   s e e   a l l   t h e   c u r r e n t   M T 5   o r d e r s  
 / /   1 6 / 1 0 / 2 0 1 7 :  
 / /       F i x :   O r d e r s H i s t o r y T o t a l ( )   r e s p o n d s   t o   c h a n g i n g   t h e   t r a d i n g   a c c o u n t   n u m b e r   d u r i n g   e x e c u t i o n .  
 / /   1 3 / 0 2 / 2 0 1 8  
 / /       A d d :   A d d e d   l o g g i n g   t h e   w r o n g   e x e c u t i o n   o f   M T 5 - O r d e r S e n d .  
 / /       F i x :   N o w   o n l y   c l o s i n g   M T 5   o r d e r s ,   s u c h   a s   S L / T P / S O   o r   p a r t i a l / f u l l   c l o s e ,   a r e   " i n v i s i b l e . "  
 / /       F i x :   M e c h a n i s m   o f   d e f i n i n g   t h e   S L / T P   o f   c l o s e d   p o s i t i o n s   a f t e r   O r d e r C l o s e   h a v i n g   b e e n   c o r r e c t e d   -   i t   w o r k s   i f   S t o p L e v e l   a l l o w s   t h i s .  
 / /   1 5 / 0 2 / 2 0 1 8  
 / /       F i x :   N o w   M T 5 - O r d e r S e n d   s y n c h r o n i z a t i o n   c h e c k   c o n s i d e r s   p o t e n t i a l   s p e c i a l   a s p e c t s   o f   i m p l e m e n t i n g   E C N / S T P .  
 / /   0 6 / 0 3 / 2 0 1 8  
 / /       A d d :   A d d e d   T I C K E T _ T Y P E   a n d   M A G I C _ T Y P E   t o   b e   a b l e   t o   w r i t e   a   u n i f i e d   c r o s s - p l a t f o r m   c o d e  
 / /                 W i t h o u t   w a r n i n g s   o f   c o m p i l e r s ,   i n c l u d i n g   t h e   M Q L 4   s t r i c t   m o d e .  
 / /   3 0 / 0 5 / 2 0 1 8  
 / /       A d d :   A c c e l e r a t e d   w o r k i n g   w i t h   t r a d i n g   h i s t o r y ;   m i d d l e   c o u r s e   w a s   s t e e r e d   i n   i m p l e m e n t a t i o n s   b e t w e e n   p e r f o r m a n c e   a n d  
 / /                 m e m o r y   c o n s u m p t i o n ,   w h i c h   i s   i m p o r t a n t   f o r   V P S .   S t a n d a r d   G e n e r i c   l i b r a r y   i s   u s e d .  
 / /                 I f   y o u   d o n ' t   w a n t   t o   u s e   t h e   G e n e r i c   l i b r a r y ,   t h e   c o n v e n t i o n a l   m o d e   i s   a v a i l a b l e   t o   w o r k   w i t h   h i s t o r y .  
 / /                 F o r   t h i s   p u r p o s e ,   w r i t e   t h e   f o l l o w i n g   s t r i n g   B E F O R E   t h e   M T 4 O r d e r s   l i b r a r y :  
 / /  
 / /                 # d e f i n e   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F   / /   D i s a b l i n g   f a s t   t r a d i n g   h i s t o r y   i m p l e m e n t a t i o n ,   d o n ' t   u s e   t h e   G e n e r i c   l i b r a r y .  
 / /   0 2 / 1 1 / 2 0 1 8  
 / /       F i x :   N o w   t h e   M T 4   p o s i t i o n   O p e n   p r i c e   c a n n o t   b e   z e r o   b e f o r e   i t s   t r i g g e r i n g .  
 / /       F i x :   C o n s i d e r e d   s o m e   r a r e   e x e c u t i o n   a s p e c t s   o f   c e r t a i n   t r a d i n g   s e r v e r s .  
 / /   2 6 / 1 1 / 2 0 1 8  
 / /       F i x :   M a g i c   a n d   c o m m e n t   o f   a   c l o s e d   M T 4   p o s i t i o n :   P r i o r i t y   o f   t h e   r e l e v a n t   f i e l d s   o f   o p e n i n g   t r a n s a c t i o n s   i s   h i g h e r   t h a n   t h a t   o f   c l o s i n g   o n e s .  
 / /       F i x :   R a r e   c h a n g e s   i n   M T 5 - O r d e r s T o t a l   a n d   M T 5 - P o s i t i o n s T o t a l   a r e   c o n s i d e r e d   w h i l e   c a l c u l a t i n g   M T 4 - O r d e r s T o t a l   a n d   M T 4 - O r d e r S e l e c t .  
 / /       F i x :   L i b r a r y   d o e s   n o t   c o n s i d e r   o r d e r s   a n y m o r e ,   w h i c h   h a v e   o p e n e d   a   p o s i t i o n ,   b u t   h a v e   n o t   h a d   t i m e   t o   b e   d e l e t e d   f r o m   M T 5 .  
 / /   1 7 / 0 1 / 2 0 1 9  
 / /       F i x :   F i x e d   a n   u n f o r t u n a t e   e r r o r   i n   s e l e c t i n g   p e n d i n g   o r d e r s .  
 / /   0 8 / 0 2 / 2 0 1 9  
 / /       A d d :   C o m m e n t   o f   a   p o s i t i o n   i s   s a v e d   a t   p a r t i a l   c l o s i n g   v i a   O r d e r C l o s e .  
 / /                 I f   y o u   n e e d   t o   m o d i f y   t h e   c o m m e n t   o n   a n   o p e n   p o s i t i o n   a t   p a r t i a l   c l o s i n g ,   y o u   c a n   s p e c i f y   i t   i n   O r d e r C l o s e .  
 / /   2 0 / 0 2 / 2 0 1 9  
 / /       F i x :   I n   c a s e   o f   n o   M T 5   o r d e r ,   t h e   l i b r a r y   w i l l   e x p e c t   t h e   h i s t o r y   s y n c h r o n i z a t i o n   f r o m   t h e   e x i s t i n g   M T 5   t r a n s a c t i o n .   I n   c a s e   o f   f a i l u r e ,   i t   w i l l   i n f o r m   a b o u t   i t .  
 / /   1 3 / 0 3 / 2 0 1 9  
 / /       A d d :   A d d e d   O r d e r T i c k e t I D ( )   -   P o s i t i o n I D   o f   a n   M T 5   t r a n s a c t i o n   o r   M T 5   p o s i t i o n ,   a n d   t h e   t i c k e t   o f   a   p e n d i n g   M T 4   o r d e r .  
 / /       A d d :   S E L E C T _ B Y _ T I C K E T   w o r k s   f o r   a l l   M T 5   t i c k e t s   ( a n d   M T 5 - P o s i t i o n I D ) .  
 / /   0 2 / 1 1 / 2 0 1 9  
 / /       F i x :   C o r r e c t e d   l o t ,   c o m m i s s i o n ,   a n d   C l o s e   p r i c e   f o r   C l o s e B y   p o s i t i o n s .  
  
 # i f d e f   _ _ M Q L 5 _ _  
 # i f n d e f   _ _ M T 4 O R D E R S _ _  
  
 # d e f i n e   _ _ M T 4 O R D E R S _ _   " 2 0 1 9 . 1 1 . 0 2 "  
 # d e f i n e   M T 4 O R D E R S _ S L T P _ O L D   / /   E n a b l i n g   t h e   o l d   m e c h a n i s m   o f   i d e n t i f y i n g   t h e   S L / T P   o f   c l o s e d   p o s i t i o n s   v i a   O r d e r C l o s e  
  
 # i f d e f   M T 4 _ T I C K E T _ T Y P E  
     # d e f i n e   T I C K E T _ T Y P E   i n t  
     # d e f i n e   M A G I C _ T Y P E     i n t  
  
     # u n d e f   M T 4 _ T I C K E T _ T Y P E  
 # e l s e   / /   M T 4 _ T I C K E T _ T Y P E  
     # d e f i n e   T I C K E T _ T Y P E   l o n g  
     # d e f i n e   M A G I C _ T Y P E     l o n g  
 # e n d i f   / /   M T 4 _ T I C K E T _ T Y P E  
  
 s t r u c t   M T 4 _ O R D E R  
 {  
     l o n g   T i c k e t ;  
     i n t   T y p e ;  
  
     l o n g   T i c k e t O p e n ;  
     l o n g   T i c k e t I D ;  
  
     d o u b l e   L o t s ;  
  
     s t r i n g   S y m b o l ;  
     s t r i n g   C o m m e n t ;  
  
     d o u b l e   O p e n P r i c e R e q u e s t ;  
     d o u b l e   O p e n P r i c e ;  
  
     l o n g   O p e n T i m e M s c ;  
     d a t e t i m e   O p e n T i m e ;  
  
     E N U M _ D E A L _ R E A S O N   O p e n R e a s o n ;  
  
     d o u b l e   S t o p L o s s ;  
     d o u b l e   T a k e P r o f i t ;  
  
     d o u b l e   C l o s e P r i c e R e q u e s t ;  
     d o u b l e   C l o s e P r i c e ;  
  
     l o n g   C l o s e T i m e M s c ;  
     d a t e t i m e   C l o s e T i m e ;  
  
     E N U M _ D E A L _ R E A S O N   C l o s e R e a s o n ;  
  
     E N U M _ O R D E R _ S T A T E   S t a t e ;  
  
     d a t e t i m e   E x p i r a t i o n ;  
  
     l o n g   M a g i c N u m b e r ;  
  
     d o u b l e   P r o f i t ;  
  
     d o u b l e   C o m m i s s i o n ;  
     d o u b l e   S w a p ;  
  
 # d e f i n e   P O S I T I O N _ S E L E C T   ( - 1 )  
 # d e f i n e   O R D E R _ S E L E C T   ( - 2 )  
  
     s t a t i c   c o n s t   M T 4 _ O R D E R   G e t P o s i t i o n D a t a (   v o i d   )  
     {  
         M T 4 _ O R D E R   R e s   =   { 0 } ;  
  
         R e s . T i c k e t   =   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I C K E T ) ;  
         R e s . T y p e   =   ( i n t ) : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T Y P E ) ;  
  
         R e s . L o t s   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ V O L U M E ) ;  
  
         R e s . S y m b o l   =   : : P o s i t i o n G e t S t r i n g ( P O S I T I O N _ S Y M B O L ) ;  
 / /         R e s . C o m m e n t   =   N U L L ;   / /   M T 4 O R D E R S : : C h e c k P o s i t i o n C o m m i s s i o n C o m m e n t ( ) ;  
  
         R e s . O p e n P r i c e   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R I C E _ O P E N ) ;  
         R e s . O p e n T i m e   =   ( d a t e t i m e ) : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I M E ) ;  
  
         R e s . S t o p L o s s   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ S L ) ;  
         R e s . T a k e P r o f i t   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ T P ) ;  
  
         R e s . C l o s e P r i c e   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R I C E _ C U R R E N T ) ;  
         R e s . C l o s e T i m e   =   0 ;  
  
         R e s . E x p i r a t i o n   =   0 ;  
  
         R e s . M a g i c N u m b e r   =   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ M A G I C ) ;  
  
         R e s . P r o f i t   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R O F I T ) ;  
  
         R e s . S w a p   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ S W A P ) ;  
  
 / /         R e s . C o m m i s s i o n   =   U N K N O W N _ C O M M I S S I O N ;   / /   M T 4 O R D E R S : : C h e c k P o s i t i o n C o m m i s s i o n C o m m e n t ( ) ;  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   c o n s t   M T 4 _ O R D E R   G e t O r d e r D a t a (   v o i d   )  
     {  
         M T 4 _ O R D E R   R e s   =   { 0 } ;  
  
         R e s . T i c k e t   =   : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T ) ;  
         R e s . T y p e   =   ( i n t ) : : O r d e r G e t I n t e g e r ( O R D E R _ T Y P E ) ;  
  
         R e s . L o t s   =   : : O r d e r G e t D o u b l e ( O R D E R _ V O L U M E _ C U R R E N T ) ;  
  
         R e s . S y m b o l   =   : : O r d e r G e t S t r i n g ( O R D E R _ S Y M B O L ) ;  
         R e s . C o m m e n t   =   : : O r d e r G e t S t r i n g ( O R D E R _ C O M M E N T ) ;  
  
         R e s . O p e n P r i c e   =   : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ O P E N ) ;  
         R e s . O p e n T i m e   =   ( d a t e t i m e ) : : O r d e r G e t I n t e g e r ( O R D E R _ T I M E _ S E T U P ) ;  
  
         R e s . S t o p L o s s   =   : : O r d e r G e t D o u b l e ( O R D E R _ S L ) ;  
         R e s . T a k e P r o f i t   =   : : O r d e r G e t D o u b l e ( O R D E R _ T P ) ;  
  
         R e s . C l o s e P r i c e   =   : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ C U R R E N T ) ;  
         R e s . C l o s e T i m e   =   0 ;   / /   ( d a t e t i m e ) : : O r d e r G e t I n t e g e r ( O R D E R _ T I M E _ D O N E )  
  
         R e s . E x p i r a t i o n   =   ( d a t e t i m e ) : : O r d e r G e t I n t e g e r ( O R D E R _ T I M E _ E X P I R A T I O N ) ;  
  
         R e s . M a g i c N u m b e r   =   : : O r d e r G e t I n t e g e r ( O R D E R _ M A G I C ) ;  
  
         R e s . P r o f i t   =   0 ;  
  
         R e s . C o m m i s s i o n   =   0 ;  
         R e s . S w a p   =   0 ;  
  
         i f   ( ! R e s . O p e n P r i c e )  
             R e s . O p e n P r i c e   =   R e s . C l o s e P r i c e ;  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t r i n g   T o S t r i n g (   v o i d   )   c o n s t  
     {  
         s t a t i c   c o n s t   s t r i n g   T y p e s [ ]   =   { " b u y " ,   " s e l l " ,   " b u y   l i m i t " ,   " s e l l   l i m i t " ,   " b u y   s t o p " ,   " s e l l   s t o p " ,   " b a l a n c e " } ;  
         c o n s t   i n t   d i g i t s   =   ( i n t ) : : S y m b o l I n f o I n t e g e r ( t h i s . S y m b o l ,   S Y M B O L _ D I G I T S ) ;  
  
         M T 4 _ O R D E R   T m p O r d e r   =   { 0 } ;  
  
         i f   ( t h i s . T i c k e t   = =   P O S I T I O N _ S E L E C T )  
         {  
             T m p O r d e r   =   M T 4 _ O R D E R : : G e t P o s i t i o n D a t a ( ) ;  
  
             T m p O r d e r . C o m m e n t   =   t h i s . C o m m e n t ;  
             T m p O r d e r . C o m m i s s i o n   =   t h i s . C o m m i s s i o n ;  
         }  
         e l s e   i f   ( t h i s . T i c k e t   = =   O R D E R _ S E L E C T )  
             T m p O r d e r   =   M T 4 _ O R D E R : : G e t O r d e r D a t a ( ) ;  
  
         r e t u r n ( ( ( t h i s . T i c k e t   = =   P O S I T I O N _ S E L E C T )   | |   ( t h i s . T i c k e t   = =   O R D E R _ S E L E C T ) )   ?   T m p O r d e r . T o S t r i n g ( )   :  
                       ( " # "   +   ( s t r i n g ) t h i s . T i c k e t   +   "   "   +  
                         ( s t r i n g ) t h i s . O p e n T i m e   +   "   "   +  
                         ( ( t h i s . T y p e   <   : : A r r a y S i z e ( T y p e s ) )   ?   T y p e s [ t h i s . T y p e ]   :   " u n k n o w n " )   +   "   "   +  
                         : : D o u b l e T o S t r i n g ( t h i s . L o t s ,   2 )   +   "   "   +  
                         ( : : S t r i n g L e n ( t h i s . S y m b o l )   ?   t h i s . S y m b o l   +   "   "   :   N U L L )   +  
                         : : D o u b l e T o S t r i n g ( t h i s . O p e n P r i c e ,   d i g i t s )   +   "   "   +  
                         : : D o u b l e T o S t r i n g ( t h i s . S t o p L o s s ,   d i g i t s )   +   "   "   +  
                         : : D o u b l e T o S t r i n g ( t h i s . T a k e P r o f i t ,   d i g i t s )   +   "   "   +  
                         ( ( t h i s . C l o s e T i m e   >   0 )   ?   ( ( s t r i n g ) t h i s . C l o s e T i m e   +   "   " )   :   " " )   +  
                         : : D o u b l e T o S t r i n g ( t h i s . C l o s e P r i c e ,   d i g i t s )   +   "   "   +  
                         : : D o u b l e T o S t r i n g ( t h i s . C o m m i s s i o n ,   2 )   +   "   "   +  
                         : : D o u b l e T o S t r i n g ( t h i s . S w a p ,   2 )   +   "   "   +  
                         : : D o u b l e T o S t r i n g ( t h i s . P r o f i t ,   2 )   +   "   "   +  
                         ( ( t h i s . C o m m e n t   = =   " " )   ?   " "   :   ( t h i s . C o m m e n t   +   "   " ) )   +  
                         ( s t r i n g ) t h i s . M a g i c N u m b e r   +  
                         ( ( ( t h i s . E x p i r a t i o n   >   0 )   ?   ( "   e x p i r a t i o n   "   +   ( s t r i n g ) t h i s . E x p i r a t i o n ) :   " " ) ) ) ) ;  
     }  
 } ;  
  
 # d e f i n e   R E S E R V E _ S I Z E   1 0 0 0  
 # d e f i n e   D A Y   ( 2 4   *   3 6 0 0 )  
 # d e f i n e   H I S T O R Y _ P A U S E   ( M T 4 H I S T O R Y : : I s T e s t e r   ?   0   :   5 )  
 # d e f i n e   E N D _ T I M E   D ' 3 1 . 1 2 . 3 0 0 0   2 3 : 5 9 : 5 9 '  
 # d e f i n e   T H O U S A N D   1 0 0 0  
 # d e f i n e   L A S T T I M E ( A )                                                                                     \  
     i f   ( T i m e # # A   > =   L a s t T i m e M s c )                                                                 \  
     {                                                                                                                     \  
         c o n s t   d a t e t i m e   T m p T i m e   =   ( d a t e t i m e ) ( T i m e # # A   /   T H O U S A N D ) ;   \  
                                                                                                                           \  
         i f   ( T m p T i m e   >   t h i s . L a s t T i m e )                                                           \  
         {                                                                                                                 \  
             t h i s . L a s t T o t a l O r d e r s   =   0 ;                                                             \  
             t h i s . L a s t T o t a l D e a l s   =   0 ;                                                               \  
                                                                                                                           \  
             t h i s . L a s t T i m e   =   T m p T i m e ;                                                               \  
             L a s t T i m e M s c   =   t h i s . L a s t T i m e   *   T H O U S A N D ;                                 \  
         }                                                                                                                 \  
                                                                                                                           \  
         t h i s . L a s t T o t a l # # A # # s + + ;                                                                     \  
     }  
  
 # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
     # i n c l u d e   < G e n e r i c \ H a s h M a p . m q h >  
 # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
  
 c l a s s   M T 4 H I S T O R Y  
 {  
 p r i v a t e :  
     s t a t i c   c o n s t   b o o l   M T 4 H I S T O R Y : : I s T e s t e r ;  
 / /     s t a t i c   l o n g   M T 4 H I S T O R Y : : A c c o u n t N u m b e r ;  
  
 # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
     C H a s h M a p < u l o n g ,   u l o n g >   D e a l s I n ;     / /   B y   P o s i t i o n I D ,   i t   r e t u r n s   D e a l I n .  
     C H a s h M a p < u l o n g ,   u l o n g >   D e a l s O u t ;   / /   B y   P o s i t i o n I D ,   i t   r e t u r n s   D e a l O u t .  
 # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
  
     l o n g   T i c k e t s [ ] ;  
     u i n t   A m o u n t ;  
  
     d a t e t i m e   L a s t T i m e ;  
  
     i n t   L a s t T o t a l D e a l s ;  
     i n t   L a s t T o t a l O r d e r s ;  
  
     d a t e t i m e   L a s t I n i t T i m e ;  
  
     b o o l   R e f r e s h H i s t o r y (   v o i d   )  
     {  
         b o o l   R e s   =   f a l s e ;  
  
         c o n s t   d a t e t i m e   L a s t T i m e C u r r e n t   =   : : T i m e C u r r e n t ( ) ;  
  
         i f   ( ! M T 4 H I S T O R Y : : I s T e s t e r   & &   ( ( L a s t T i m e C u r r e n t   > =   t h i s . L a s t I n i t T i m e   +   D A Y ) / *   | |   ( M T 4 H I S T O R Y : : A c c o u n t N u m b e r   ! =   : : A c c o u n t I n f o I n t e g e r ( A C C O U N T _ L O G I N ) ) * / ) )  
         {  
         / /     M T 4 H I S T O R Y : : A c c o u n t N u m b e r   =   : : A c c o u n t I n f o I n t e g e r ( A C C O U N T _ L O G I N ) ;  
  
             t h i s . L a s t T i m e   =   0 ;  
  
             t h i s . L a s t T o t a l O r d e r s   =   0 ;  
             t h i s . L a s t T o t a l D e a l s   =   0 ;  
  
             t h i s . A m o u n t   =   0 ;  
  
             : : A r r a y R e s i z e ( t h i s . T i c k e t s ,   t h i s . A m o u n t ,   R E S E R V E _ S I Z E ) ;  
  
             t h i s . L a s t I n i t T i m e   =   L a s t T i m e C u r r e n t ;  
  
         # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
             t h i s . D e a l s I n . C l e a r ( ) ;  
             t h i s . D e a l s O u t . C l e a r ( ) ;  
         # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
         }  
  
         c o n s t   d a t e t i m e   L a s t T i m e C u r r e n t L e f t   =   L a s t T i m e C u r r e n t   -   H I S T O R Y _ P A U S E ;  
  
         i f   ( : : H i s t o r y S e l e c t ( t h i s . L a s t T i m e ,   E N D _ T I M E ) )   / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 2 8 5 6 3 1 / p a g e 7 9 # c o m m e n t _ 9 8 8 4 9 3 5  
         {  
             c o n s t   i n t   T o t a l O r d e r s   =   : : H i s t o r y O r d e r s T o t a l ( ) ;  
             c o n s t   i n t   T o t a l D e a l s   =   : : H i s t o r y D e a l s T o t a l ( ) ;  
  
             R e s   =   ( ( T o t a l O r d e r s   >   t h i s . L a s t T o t a l O r d e r s )   | |   ( T o t a l D e a l s   >   t h i s . L a s t T o t a l D e a l s ) ) ;  
  
             i f   ( R e s )  
             {  
                 i n t   i O r d e r   =   t h i s . L a s t T o t a l O r d e r s ;  
                 i n t   i D e a l   =   t h i s . L a s t T o t a l D e a l s ;  
  
                 u l o n g   T i c k e t O r d e r   =   0 ;  
                 u l o n g   T i c k e t D e a l   =   0 ;  
  
                 l o n g   T i m e O r d e r   =   ( i O r d e r   <   T o t a l O r d e r s )   ?   : : H i s t o r y O r d e r G e t I n t e g e r ( ( T i c k e t O r d e r   =   : : H i s t o r y O r d e r G e t T i c k e t ( i O r d e r ) ) ,   O R D E R _ T I M E _ D O N E _ M S C )   :   L O N G _ M A X ;  
                 l o n g   T i m e D e a l   =   ( i D e a l   <   T o t a l D e a l s )   ?   : : H i s t o r y D e a l G e t I n t e g e r ( ( T i c k e t D e a l   =   : : H i s t o r y D e a l G e t T i c k e t ( i D e a l ) ) ,   D E A L _ T I M E _ M S C )   :   L O N G _ M A X ;  
  
                 i f   ( t h i s . L a s t T i m e   <   L a s t T i m e C u r r e n t L e f t )  
                 {  
                     t h i s . L a s t T o t a l O r d e r s   =   0 ;  
                     t h i s . L a s t T o t a l D e a l s   =   0 ;  
  
                     t h i s . L a s t T i m e   =   L a s t T i m e C u r r e n t L e f t ;  
                 }  
  
                 l o n g   L a s t T i m e M s c   =   t h i s . L a s t T i m e   *   T H O U S A N D ;  
  
                 w h i l e   ( ( i D e a l   <   T o t a l D e a l s )   | |   ( i O r d e r   <   T o t a l O r d e r s ) )  
                     i f   ( T i m e O r d e r   <   T i m e D e a l )  
                     {  
                         L A S T T I M E ( O r d e r )  
  
                         i f   ( M T 4 H I S T O R Y : : I s M T 4 O r d e r ( T i c k e t O r d e r ) )  
                         {  
                             t h i s . A m o u n t   =   : : A r r a y R e s i z e ( t h i s . T i c k e t s ,   t h i s . A m o u n t   +   1 ,   R E S E R V E _ S I Z E ) ;  
  
                             t h i s . T i c k e t s [ t h i s . A m o u n t   -   1 ]   =   - ( l o n g ) T i c k e t O r d e r ;  
                         }  
  
                         i O r d e r + + ;  
  
                         T i m e O r d e r   =   ( i O r d e r   <   T o t a l O r d e r s )   ?   : : H i s t o r y O r d e r G e t I n t e g e r ( ( T i c k e t O r d e r   =   : : H i s t o r y O r d e r G e t T i c k e t ( i O r d e r ) ) ,   O R D E R _ T I M E _ D O N E _ M S C )   :   L O N G _ M A X ;  
                     }  
                     e l s e  
                     {  
                         L A S T T I M E ( D e a l )  
  
                         i f   ( M T 4 H I S T O R Y : : I s M T 4 D e a l ( T i c k e t D e a l ) )  
                         {  
                             t h i s . A m o u n t   =   : : A r r a y R e s i z e ( t h i s . T i c k e t s ,   t h i s . A m o u n t   +   1 ,   R E S E R V E _ S I Z E ) ;  
  
                             t h i s . T i c k e t s [ t h i s . A m o u n t   -   1 ]   =   ( l o n g ) T i c k e t D e a l ;  
  
                         # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
                             t h i s . D e a l s O u t . A d d ( : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t D e a l ,   D E A L _ P O S I T I O N _ I D ) ,   T i c k e t D e a l ) ;  
                         # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
                         }  
                     # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
                         e l s e   i f   ( ( E N U M _ D E A L _ E N T R Y ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t D e a l ,   D E A L _ E N T R Y )   = =   D E A L _ E N T R Y _ I N )  
                             t h i s . D e a l s I n . A d d ( : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t D e a l ,   D E A L _ P O S I T I O N _ I D ) ,   T i c k e t D e a l ) ;  
                     # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
  
                         i D e a l + + ;  
  
                         T i m e D e a l   =   ( i D e a l   <   T o t a l D e a l s )   ?   : : H i s t o r y D e a l G e t I n t e g e r ( ( T i c k e t D e a l   =   : : H i s t o r y D e a l G e t T i c k e t ( i D e a l ) ) ,   D E A L _ T I M E _ M S C )   :   L O N G _ M A X ;  
                     }  
             }  
             e l s e   i f   ( L a s t T i m e C u r r e n t L e f t   >   t h i s . L a s t T i m e )  
             {  
                 t h i s . L a s t T i m e   =   L a s t T i m e C u r r e n t L e f t ;  
  
                 t h i s . L a s t T o t a l O r d e r s   =   0 ;  
                 t h i s . L a s t T o t a l D e a l s   =   0 ;  
             }  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
 p u b l i c :  
     s t a t i c   b o o l   I s M T 4 D e a l (   c o n s t   u l o n g   & T i c k e t   )  
     {  
         c o n s t   E N U M _ D E A L _ T Y P E   D e a l T y p e   =   ( E N U M _ D E A L _ T Y P E ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ T Y P E ) ;  
         c o n s t   E N U M _ D E A L _ E N T R Y   D e a l E n t r y   =   ( E N U M _ D E A L _ E N T R Y ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ E N T R Y ) ;  
  
         r e t u r n ( ( ( D e a l T y p e   ! =   D E A L _ T Y P E _ B U Y )   & &   ( D e a l T y p e   ! =   D E A L _ T Y P E _ S E L L ) )   | |             / /   n o n   t r a d i n g   d e a l  
                       ( ( D e a l E n t r y   = =   D E A L _ E N T R Y _ O U T )   | |   ( D e a l E n t r y   = =   D E A L _ E N T R Y _ O U T _ B Y ) ) ) ;   / /   t r a d i n g  
     }  
  
     s t a t i c   b o o l   I s M T 4 O r d e r (   c o n s t   u l o n g   & T i c k e t   )  
     {  
         / /   I f   t h e   p e n d i n g   o r d e r   h a s   b e e n   e x e c u t e d ,   i t s   O R D E R _ P O S I T I O N _ I D   i s   f i l l e d   o u t .  
         / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 1 7 0 9 5 2 / p a g e 7 0 # c o m m e n t _ 6 5 4 3 1 6 2  
         / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 9 3 3 5 2 / p a g e 1 9 # c o m m e n t _ 6 6 4 6 7 2 6  
         / /   W h a t   t o   d o ,   i f   a   l i m i t   o r d e r   h a s   b e e n   p a r t i a l l y   e x e c u t e d   a n d   t h e n   d e l e t e d ?  
         r e t u r n ( / * ( : : H i s t o r y O r d e r G e t D o u b l e ( T i c k e t ,   O R D E R _ V O L U M E _ C U R R E N T )   >   0 )   | | * /   ! : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ P O S I T I O N _ I D ) ) ;  
     }  
  
     M T 4 H I S T O R Y (   v o i d   )   :   A m o u n t ( : : A r r a y R e s i z e ( t h i s . T i c k e t s ,   0 ,   R E S E R V E _ S I Z E ) ) ,  
                                               L a s t T i m e ( 0 ) ,   L a s t T o t a l D e a l s ( 0 ) ,   L a s t T o t a l O r d e r s ( 0 ) ,   L a s t I n i t T i m e ( 0 )  
     {  
 / /         t h i s . R e f r e s h H i s t o r y ( ) ;   / /   I f   h i s t o r y   i s   n o t   u s e d ,   t h e r e   i s   n o   p o i n t   i n   w a s t i n g   r e s o u r c e s .  
     }  
  
     u l o n g   G e t P o s i t i o n D e a l I n (   c o n s t   u l o n g   P o s i t i o n I d e n t i f i e r   =   - 1   )   / /   0   i s   n o t   a v a i l a b l e ,   s i n c e   t h e   t e s t e r ' s   b a l a n c e   t r a d e   i s   z e r o  
     {  
         u l o n g   T i c k e t   =   0 ;  
  
         i f   ( P o s i t i o n I d e n t i f i e r   = =   - 1 )  
         {  
             c o n s t   u l o n g   M y P o s i t i o n I d e n t i f i e r   =   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ I D E N T I F I E R ) ;  
  
         # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
             i f   ( ! t h i s . D e a l s I n . T r y G e t V a l u e ( M y P o s i t i o n I d e n t i f i e r ,   T i c k e t ) )  
         # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
             {  
                 c o n s t   d a t e t i m e   P o s T i m e   =   ( d a t e t i m e ) : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I M E ) ;  
  
                 i f   ( : : H i s t o r y S e l e c t ( P o s T i m e ,   P o s T i m e ) )  
                 {  
                     c o n s t   i n t   T o t a l   =   : : H i s t o r y D e a l s T o t a l ( ) ;  
  
                     f o r   ( i n t   i   =   0 ;   i   <   T o t a l ;   i + + )  
                     {  
                         c o n s t   u l o n g   T i c k e t D e a l   =   : : H i s t o r y D e a l G e t T i c k e t ( i ) ;  
  
                         i f   ( ( : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t D e a l ,   D E A L _ P O S I T I O N _ I D )   = =   M y P o s i t i o n I d e n t i f i e r )   / * & &  
                                 ( ( E N U M _ D E A L _ E N T R Y ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t D e a l ,   D E A L _ E N T R Y )   = =   D E A L _ E N T R Y _ I N )   * / )   / /   F i r s t   m e n t i o n   w i l l   b e   D E A L _ E N T R Y _ I N   a n y w a y  
                         {  
                             T i c k e t   =   T i c k e t D e a l ;  
  
                         # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
                             t h i s . D e a l s I n . A d d ( M y P o s i t i o n I d e n t i f i e r ,   T i c k e t ) ;  
                         # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
  
                             b r e a k ;  
                         }  
                     }  
                 }  
             }  
         }  
         e l s e   i f   ( P o s i t i o n I d e n t i f i e r   & &   / /   P o s i t i o n I d e n t i f i e r   o f   b a l a n c e   t r a d e s   i s   z e r o  
                       # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
                           ! t h i s . D e a l s I n . T r y G e t V a l u e ( P o s i t i o n I d e n t i f i e r ,   T i c k e t )   & &  
                       # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
                           : : H i s t o r y S e l e c t B y P o s i t i o n ( P o s i t i o n I d e n t i f i e r )   & &   ( : : H i s t o r y D e a l s T o t a l ( )   >   1 ) )   / /   >G5<C  >   1 ,   0  =5  >   0   ? !  
         {  
             T i c k e t   =   : : H i s t o r y D e a l G e t T i c k e t ( 0 ) ;   / /   F i r s t   m e n t i o n   w i l l   b e   D E A L _ E N T R Y _ I N   a n y w a y  
  
             / *  
             c o n s t   i n t   T o t a l   =   : : H i s t o r y D e a l s T o t a l ( ) ;  
  
             f o r   ( i n t   i   =   0 ;   i   <   T o t a l ;   i + + )  
             {  
                 c o n s t   u l o n g   T i c k e t D e a l   =   : : H i s t o r y D e a l G e t T i c k e t ( i ) ;  
  
                 i f   ( T i c k e t D e a l   >   0 )  
                     i f   ( ( E N U M _ D E A L _ E N T R Y ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t D e a l ,   D E A L _ E N T R Y )   = =   D E A L _ E N T R Y _ I N )  
                     {  
                         T i c k e t   =   T i c k e t D e a l ;  
  
                         b r e a k ;  
                     }  
             }   * /  
  
         # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
             t h i s . D e a l s I n . A d d ( P o s i t i o n I d e n t i f i e r ,   T i c k e t ) ;  
         # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
         }  
  
         r e t u r n ( T i c k e t ) ;  
     }  
  
     u l o n g   G e t P o s i t i o n D e a l O u t (   c o n s t   u l o n g   P o s i t i o n I d e n t i f i e r   )  
     {  
         u l o n g   T i c k e t   =   0 ;  
  
     # i f n d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
         i f   ( ! t h i s . D e a l s O u t . T r y G e t V a l u e ( P o s i t i o n I d e n t i f i e r ,   T i c k e t )   & &   t h i s . R e f r e s h H i s t o r y ( ) )  
             t h i s . D e a l s O u t . T r y G e t V a l u e ( P o s i t i o n I d e n t i f i e r ,   T i c k e t ) ;  
         # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
  
         r e t u r n ( T i c k e t ) ;  
     }  
  
     i n t   G e t A m o u n t (   v o i d   )  
     {  
         t h i s . R e f r e s h H i s t o r y ( ) ;  
  
         r e t u r n ( ( i n t ) t h i s . A m o u n t ) ;  
     }  
  
     l o n g   o p e r a t o r   [ ] (   c o n s t   u i n t   & P o s   )  
     {  
         l o n g   R e s   =   0 ;  
  
         i f   ( ( P o s   > =   t h i s . A m o u n t ) / *   | |   ( ! M T 4 H I S T O R Y : : I s T e s t e r   & &   ( M T 4 H I S T O R Y : : A c c o u n t N u m b e r   ! =   : : A c c o u n t I n f o I n t e g e r ( A C C O U N T _ L O G I N ) ) ) * / )  
         {  
             t h i s . R e f r e s h H i s t o r y ( ) ;  
  
             i f   ( P o s   <   t h i s . A m o u n t )  
                 R e s   =   t h i s . T i c k e t s [ P o s ] ;  
         }  
         e l s e  
             R e s   =   t h i s . T i c k e t s [ P o s ] ;  
  
         r e t u r n ( R e s ) ;  
     }  
 } ;  
  
 s t a t i c   c o n s t   b o o l   M T 4 H I S T O R Y : : I s T e s t e r   =   : : M Q L I n f o I n t e g e r ( M Q L _ T E S T E R ) ;  
 / /   s t a t i c   l o n g   M T 4 H I S T O R Y : : A c c o u n t N u m b e r   =   : : A c c o u n t I n f o I n t e g e r ( A C C O U N T _ L O G I N ) ;  
  
 # u n d e f   L A S T T I M E  
 # u n d e f   T H O U S A N D  
 # u n d e f   E N D _ T I M E  
 # u n d e f   H I S T O R Y _ P A U S E  
 # u n d e f   D A Y  
 # u n d e f   R E S E R V E _ S I Z E  
  
 # d e f i n e   O P _ B U Y   O R D E R _ T Y P E _ B U Y  
 # d e f i n e   O P _ S E L L   O R D E R _ T Y P E _ S E L L  
 # d e f i n e   O P _ B U Y L I M I T   O R D E R _ T Y P E _ B U Y _ L I M I T  
 # d e f i n e   O P _ S E L L L I M I T   O R D E R _ T Y P E _ S E L L _ L I M I T  
 # d e f i n e   O P _ B U Y S T O P   O R D E R _ T Y P E _ B U Y _ S T O P  
 # d e f i n e   O P _ S E L L S T O P   O R D E R _ T Y P E _ S E L L _ S T O P  
 # d e f i n e   O P _ B A L A N C E   6  
  
 # d e f i n e   S E L E C T _ B Y _ P O S   0  
 # d e f i n e   S E L E C T _ B Y _ T I C K E T   1  
  
 # d e f i n e   M O D E _ T R A D E S   0  
 # d e f i n e   M O D E _ H I S T O R Y   1  
  
 c l a s s   M T 4 O R D E R S  
 {  
 p r i v a t e :  
     s t a t i c   M T 4 _ O R D E R   O r d e r ;  
     s t a t i c   M T 4 H I S T O R Y   H i s t o r y ;  
  
     s t a t i c   c o n s t   b o o l   M T 4 O R D E R S : : I s T e s t e r ;  
     s t a t i c   c o n s t   b o o l   M T 4 O R D E R S : : I s H e d g i n g ;  
  
     s t a t i c   i n t   O r d e r S e n d B u g ;  
  
     s t a t i c   b o o l   H i s t o r y S e l e c t O r d e r (   c o n s t   u l o n g   & T i c k e t   )  
     {  
         r e t u r n ( ( : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ T I C K E T )   = =   T i c k e t )   | |   : : H i s t o r y O r d e r S e l e c t ( T i c k e t ) ) ;  
     }  
  
     s t a t i c   b o o l   H i s t o r y S e l e c t D e a l (   c o n s t   u l o n g   & T i c k e t   )  
     {  
         r e t u r n ( ( : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ T I C K E T )   = =   T i c k e t )   | |   : : H i s t o r y D e a l S e l e c t ( T i c k e t ) ) ;  
     }  
  
 # d e f i n e   U N K N O W N _ C O M M I S S I O N   D B L _ M I N  
 # d e f i n e   U N K N O W N _ R E Q U E S T _ P R I C E   D B L _ M I N  
 # d e f i n e   U N K N O W N _ T I C K E T   0  
 / /   # d e f i n e   U N K N O W N _ R E A S O N   ( - 1 )  
  
     s t a t i c   b o o l   C h e c k N e w T i c k e t (   v o i d   )  
     {  
         s t a t i c   l o n g   P r e v P o s T i m e U p d a t e   =   0 ;  
         s t a t i c   l o n g   P r e v P o s T i c k e t   =   0 ;  
  
         c o n s t   l o n g   P o s T i m e U p d a t e   =   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I M E _ U P D A T E _ M S C ) ;  
         c o n s t   l o n g   P o s T i c k e t   =   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I C K E T ) ;  
  
         / /   I n   c a s e   t h a t   t h e   u s e r   h a s   n o t   c h o s e n   a   p o s i t i o n   v i a   M T 4 O r d e r s  
         / /   T h e r e   i s   n o   r e a s o n   t o   o v e r l o a d   M Q L 5 - P o s i t i o n S e l e c t *   a n d   M Q L 5 - O r d e r S e l e c t .  
         / /   T h i s   c h e c k   i s   s u f f i c i e n t ,   s i n c e   s e v e r a l   c h a n g e s   o f   p o s i t i o n   +   P o s i t i o n S e l e c t   p e r   m i l l i s e c o n d   a r e   o n l y   p o s s i b l e   i n   t e s t e r  
         c o n s t   b o o l   R e s   =   ( ( P o s T i m e U p d a t e   ! =   P r e v P o s T i m e U p d a t e )   | |   ( P o s T i c k e t   ! =   P r e v P o s T i c k e t ) ) ;  
  
         i f   ( R e s )  
         {  
             M T 4 O R D E R S : : G e t P o s i t i o n D a t a ( ) ;  
  
             P r e v P o s T i m e U p d a t e   =   P o s T i m e U p d a t e ;  
             P r e v P o s T i c k e t   =   P o s T i c k e t ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   C h e c k P o s i t i o n T i c k e t O p e n (   v o i d   )  
     {  
         i f   ( ( M T 4 O R D E R S : : O r d e r . T i c k e t O p e n   = =   U N K N O W N _ T I C K E T )   | |   M T 4 O R D E R S : : C h e c k N e w T i c k e t ( ) )  
             M T 4 O R D E R S : : O r d e r . T i c k e t O p e n   =   ( l o n g ) M T 4 O R D E R S : : H i s t o r y . G e t P o s i t i o n D e a l I n ( ) ;   / /   A l l   b e c a u s e   o f   t h i s   v e r y   e x p e n s i v e   f u n c t i o n  
  
         r e t u r n ( t r u e ) ;  
     }  
  
     s t a t i c   b o o l   C h e c k P o s i t i o n C o m m i s s i o n C o m m e n t (   v o i d   )  
     {  
         i f   ( ( M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   = =   U N K N O W N _ C O M M I S S I O N )   | |   M T 4 O R D E R S : : C h e c k N e w T i c k e t ( ) )  
         {  
             M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ C O M M I S S I O N ) ;   / /   A l w a y s   z e r o  
             M T 4 O R D E R S : : O r d e r . C o m m e n t   =   : : P o s i t i o n G e t S t r i n g ( P O S I T I O N _ C O M M E N T ) ;  
  
             i f   ( ! M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   | |   ( M T 4 O R D E R S : : O r d e r . C o m m e n t   = =   " " ) )  
             {  
                 M T 4 O R D E R S : : C h e c k P o s i t i o n T i c k e t O p e n ( ) ;  
  
                 c o n s t   u l o n g   T i c k e t   =   M T 4 O R D E R S : : O r d e r . T i c k e t O p e n ;  
  
                 i f   ( ( T i c k e t   >   0 )   & &   M T 4 O R D E R S : : H i s t o r y S e l e c t D e a l ( T i c k e t ) )  
                 {  
                     i f   ( ! M T 4 O R D E R S : : O r d e r . C o m m i s s i o n )  
                     {  
                         c o n s t   d o u b l e   L o t s I n   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ V O L U M E ) ;  
  
                         i f   ( L o t s I n   >   0 )  
                             M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ C O M M I S S I O N )   *   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ V O L U M E )   /   L o t s I n ;  
                     }  
  
                     i f   ( M T 4 O R D E R S : : O r d e r . C o m m e n t   = =   " " )  
                         M T 4 O R D E R S : : O r d e r . C o m m e n t   =   : : H i s t o r y D e a l G e t S t r i n g ( T i c k e t ,   D E A L _ C O M M E N T ) ;  
                 }  
             }  
         }  
  
         r e t u r n ( t r u e ) ;  
     }  
 / *  
     s t a t i c   b o o l   C h e c k P o s i t i o n O p e n R e a s o n (   v o i d   )  
     {  
         i f   ( ( M T 4 O R D E R S : : O r d e r . O p e n R e a s o n   = =   U N K N O W N _ R E A S O N )   | |   M T 4 O R D E R S : : C h e c k N e w T i c k e t ( ) )  
         {  
             M T 4 O R D E R S : : C h e c k P o s i t i o n T i c k e t O p e n ( ) ;  
  
             c o n s t   u l o n g   T i c k e t   =   M T 4 O R D E R S : : O r d e r . T i c k e t O p e n ;  
  
             i f   ( ( T i c k e t   >   0 )   & &   ( M T 4 O R D E R S : : I s T e s t e r   | |   M T 4 O R D E R S : : H i s t o r y S e l e c t D e a l ( T i c k e t ) ) )  
                 M T 4 O R D E R S : : O r d e r . O p e n R e a s o n   =   ( E N U M _ D E A L _ R E A S O N ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ R E A S O N ) ;  
         }  
  
         r e t u r n ( t r u e ) ;  
     }  
 * /  
     s t a t i c   b o o l   C h e c k P o s i t i o n O p e n P r i c e R e q u e s t (   v o i d   )  
     {  
         c o n s t   l o n g   P o s T i c k e t   =   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I C K E T ) ;  
  
         i f   ( ( ( M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   = =   U N K N O W N _ R E Q U E S T _ P R I C E )   | |   M T 4 O R D E R S : : C h e c k N e w T i c k e t ( ) )   & &  
                 ! ( M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   ( : : H i s t o r y O r d e r S e l e c t ( P o s T i c k e t )   & &  
                                                                                             ( M T 4 O R D E R S : : I s T e s t e r   | |   ( : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I M E _ M S C )   = =  
                                                                                             : : H i s t o r y O r d e r G e t I n t e g e r ( P o s T i c k e t ,   O R D E R _ T I M E _ D O N E _ M S C ) ) ) )   / /   I s   t h i s   c h e c k   n e c e s s a r y ?  
                                                                                         ?   : : H i s t o r y O r d e r G e t D o u b l e ( P o s T i c k e t ,   O R D E R _ P R I C E _ O P E N )  
                                                                                         :   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R I C E _ O P E N ) ) )  
             M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R I C E _ O P E N ) ;   / /   I n   c a s e   t h e   o r d e r   p r i c e   i s   z e r o  
  
         r e t u r n ( t r u e ) ;  
     }  
  
     s t a t i c   v o i d   G e t P o s i t i o n D a t a (   v o i d   )  
     {  
         M T 4 O R D E R S : : O r d e r . T i c k e t   =   P O S I T I O N _ S E L E C T ;  
  
         M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   =   U N K N O W N _ C O M M I S S I O N ;   / /   M T 4 O R D E R S : : C h e c k P o s i t i o n C o m m i s s i o n C o m m e n t ( ) ;  
         M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   U N K N O W N _ R E Q U E S T _ P R I C E ;   / /   M T 4 O R D E R S : : C h e c k P o s i t i o n O p e n P r i c e R e q u e s t ( )  
         M T 4 O R D E R S : : O r d e r . T i c k e t O p e n   =   U N K N O W N _ T I C K E T ;  
 / /         M T 4 O R D E R S : : O r d e r . O p e n R e a s o n   =   U N K N O W N _ R E A S O N ;  
  
         r e t u r n ;  
     }  
  
 / /   # u n d e f   U N K N O W N _ R E A S O N  
 # u n d e f   U N K N O W N _ T I C K E T  
 # u n d e f   U N K N O W N _ R E Q U E S T _ P R I C E  
 # u n d e f   U N K N O W N _ C O M M I S S I O N  
  
     s t a t i c   v o i d   G e t O r d e r D a t a (   v o i d   )  
     {  
         M T 4 O R D E R S : : O r d e r . T i c k e t   =   O R D E R _ S E L E C T ;  
  
         r e t u r n ;  
     }  
  
     s t a t i c   v o i d   G e t H i s t o r y O r d e r D a t a (   c o n s t   u l o n g   T i c k e t   )  
     {  
         M T 4 O R D E R S : : O r d e r . T i c k e t   =   : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ T I C K E T ) ;  
         M T 4 O R D E R S : : O r d e r . T y p e   =   ( i n t ) : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ T Y P E ) ;  
  
         M T 4 O R D E R S : : O r d e r . T i c k e t O p e n   =   M T 4 O R D E R S : : O r d e r . T i c k e t ;  
         M T 4 O R D E R S : : O r d e r . T i c k e t I D   =   M T 4 O R D E R S : : O r d e r . T i c k e t ;  
  
         M T 4 O R D E R S : : O r d e r . L o t s   =   : : H i s t o r y O r d e r G e t D o u b l e ( T i c k e t ,   O R D E R _ V O L U M E _ C U R R E N T ) ;  
  
         i f   ( ! M T 4 O R D E R S : : O r d e r . L o t s )  
             M T 4 O R D E R S : : O r d e r . L o t s   =   : : H i s t o r y O r d e r G e t D o u b l e ( T i c k e t ,   O R D E R _ V O L U M E _ I N I T I A L ) ;  
  
         M T 4 O R D E R S : : O r d e r . S y m b o l   =   : : H i s t o r y O r d e r G e t S t r i n g ( T i c k e t ,   O R D E R _ S Y M B O L ) ;  
         M T 4 O R D E R S : : O r d e r . C o m m e n t   =   : : H i s t o r y O r d e r G e t S t r i n g ( T i c k e t ,   O R D E R _ C O M M E N T ) ;  
  
         M T 4 O R D E R S : : O r d e r . O p e n T i m e M s c   =   : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ T I M E _ S E T U P _ M S C ) ;  
         M T 4 O R D E R S : : O r d e r . O p e n T i m e   =   ( d a t e t i m e ) ( M T 4 O R D E R S : : O r d e r . O p e n T i m e M s c   /   1 0 0 0 ) ;  
  
         M T 4 O R D E R S : : O r d e r . O p e n P r i c e   =   : : H i s t o r y O r d e r G e t D o u b l e ( T i c k e t ,   O R D E R _ P R I C E _ O P E N ) ;  
         M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . O p e n P r i c e ;  
  
         M T 4 O R D E R S : : O r d e r . O p e n R e a s o n   =   ( E N U M _ D E A L _ R E A S O N ) : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ R E A S O N ) ;  
  
         M T 4 O R D E R S : : O r d e r . S t o p L o s s   =   : : H i s t o r y O r d e r G e t D o u b l e ( T i c k e t ,   O R D E R _ S L ) ;  
         M T 4 O R D E R S : : O r d e r . T a k e P r o f i t   =   : : H i s t o r y O r d e r G e t D o u b l e ( T i c k e t ,   O R D E R _ T P ) ;  
  
         M T 4 O R D E R S : : O r d e r . C l o s e T i m e M s c   =   : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ T I M E _ D O N E _ M S C ) ;  
         M T 4 O R D E R S : : O r d e r . C l o s e T i m e   =   ( d a t e t i m e ) ( M T 4 O R D E R S : : O r d e r . C l o s e T i m e M s c   /   1 0 0 0 ) ;  
  
         M T 4 O R D E R S : : O r d e r . C l o s e P r i c e   =   : : H i s t o r y O r d e r G e t D o u b l e ( T i c k e t ,   O R D E R _ P R I C E _ C U R R E N T ) ;  
         M T 4 O R D E R S : : O r d e r . C l o s e P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . C l o s e P r i c e ;  
  
         M T 4 O R D E R S : : O r d e r . C l o s e R e a s o n   =   M T 4 O R D E R S : : O r d e r . O p e n R e a s o n ;  
  
         M T 4 O R D E R S : : O r d e r . S t a t e   =   ( E N U M _ O R D E R _ S T A T E ) : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ S T A T E ) ;  
  
         M T 4 O R D E R S : : O r d e r . E x p i r a t i o n   =   ( d a t e t i m e ) : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ T I M E _ E X P I R A T I O N ) ;  
  
         M T 4 O R D E R S : : O r d e r . M a g i c N u m b e r   =   : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ M A G I C ) ;  
  
         M T 4 O R D E R S : : O r d e r . P r o f i t   =   0 ;  
  
         M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   =   0 ;  
         M T 4 O R D E R S : : O r d e r . S w a p   =   0 ;  
  
         r e t u r n ;  
     }  
  
     s t a t i c   s t r i n g   G e t T i c k F l a g (   u i n t   t i c k f l a g   )  
     {  
         s t r i n g   f l a g   =   "   "   +   ( s t r i n g ) t i c k f l a g ;  
  
     # d e f i n e   T I C K F L A G _ M A C R O ( A )   f l a g   + =   ( ( b o o l ) ( t i c k f l a g   &   T I C K _ F L A G _ # # A ) )   ?   "   T I C K _ F L A G _ "   +   # A   :   " " ;   \  
                                                         t i c k f l a g   - =   t i c k f l a g   &   T I C K _ F L A G _ # # A ;  
         T I C K F L A G _ M A C R O ( B I D )  
         T I C K F L A G _ M A C R O ( A S K )  
         T I C K F L A G _ M A C R O ( L A S T )  
         T I C K F L A G _ M A C R O ( V O L U M E )  
         T I C K F L A G _ M A C R O ( B U Y )  
         T I C K F L A G _ M A C R O ( S E L L )  
     # u n d e f   T I C K F L A G _ M A C R O  
  
         i f   ( t i c k f l a g )  
             f l a g   + =   "   F L A G _ U N K N O W N   ( "   +   ( s t r i n g ) t i c k f l a g   +   " ) " ;  
  
         r e t u r n ( f l a g ) ;  
     }  
  
 # d e f i n e   T O S T R ( A )   "   "   +   # A   +   "   =   "   +   ( s t r i n g ) T i c k . A  
 # d e f i n e   T O S T R 2 ( A )   "   "   +   # A   +   "   =   "   +   : : D o u b l e T o S t r i n g ( T i c k . A ,   d i g i t s )  
 # d e f i n e   T O S T R 3 ( A )   "   "   +   # A   +   "   =   "   +   ( s t r i n g ) ( A )  
  
     s t a t i c   s t r i n g   T i c k T o S t r i n g (   c o n s t   s t r i n g   & S y m b ,   c o n s t   M q l T i c k   & T i c k   )  
     {  
         c o n s t   i n t   d i g i t s   =   ( i n t ) : : S y m b o l I n f o I n t e g e r ( S y m b ,   S Y M B O L _ D I G I T S ) ;  
  
         r e t u r n ( T O S T R 3 ( S y m b )   +   T O S T R ( t i m e )   +   " . "   +   : : I n t e g e r T o S t r i n g ( T i c k . t i m e _ m s c   %   1 0 0 0 ,   3 ,   ' 0 ' )   +  
                       T O S T R 2 ( b i d )   +   T O S T R 2 ( a s k )   +   T O S T R 2 ( l a s t ) +   T O S T R ( v o l u m e )   +   M T 4 O R D E R S : : G e t T i c k F l a g ( T i c k . f l a g s ) ) ;  
     }  
  
     s t a t i c   s t r i n g   T i c k T o S t r i n g (   c o n s t   s t r i n g   & S y m b   )  
     {  
         M q l T i c k   T i c k   =   { 0 } ;  
  
         r e t u r n ( T O S T R 3 ( : : S y m b o l I n f o T i c k ( S y m b ,   T i c k ) )   +   M T 4 O R D E R S : : T i c k T o S t r i n g ( S y m b ,   T i c k ) ) ;  
     }  
  
 # u n d e f   T O S T R 3  
 # u n d e f   T O S T R 2  
 # u n d e f   T O S T R  
  
     s t a t i c   v o i d   A l e r t L o g (   v o i d   )  
     {  
         : : A l e r t ( " P l e a s e   s e n d   t h e   l o g s   t o   t h e   c o a u t h o r   -   h t t p s : / / w w w . m q l 5 . c o m / e n / u s e r s / f x s a b e r " ) ;  
  
         s t r i n g   S t r   =   : : T i m e T o S t r i n g ( : : T i m e L o c a l ( ) ,   T I M E _ D A T E ) ;  
         : : S t r i n g R e p l a c e ( S t r ,   " . " ,   N U L L ) ;  
  
         : : A l e r t ( : : T e r m i n a l I n f o S t r i n g ( T E R M I N A L _ P A T H )   +   " \ \ M Q L 5 \ \ L o g s \ \ "   +   S t r   +   " . l o g " ) ;  
  
         r e t u r n ;  
     }  
  
     s t a t i c   l o n g   G e t T i m e C u r r e n t (   v o i d   )  
     {  
         l o n g   R e s   =   0 ;  
         M q l T i c k   T i c k   =   { 0 } ;  
  
         f o r   ( i n t   i   =   : : S y m b o l s T o t a l ( t r u e )   -   1 ;   i   > =   0 ;   i - - )  
         {  
             c o n s t   s t r i n g   S y m b N a m e   =   : : S y m b o l N a m e ( i ,   t r u e ) ;  
  
             i f   ( ! : : S y m b o l I n f o I n t e g e r ( S y m b N a m e ,   S Y M B O L _ C U S T O M )   & &   : : S y m b o l I n f o T i c k ( S y m b N a m e ,   T i c k )   & &   ( T i c k . t i m e _ m s c   >   R e s ) )  
                 R e s   =   T i c k . t i m e _ m s c ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   s t r i n g   T i m e T o S t r i n g (   c o n s t   l o n g   t i m e   )  
     {  
         r e t u r n ( ( s t r i n g ) ( d a t e t i m e ) ( t i m e   /   1 0 0 0 )   +   " . "   +   : : I n t e g e r T o S t r i n g ( t i m e   %   1 0 0 0 ,   3 ,   ' 0 ' ) ) ;  
     }  
  
 # d e f i n e   W H I L E ( A )   w h i l e   ( ( ! ( R e s   =   ( A ) ) )   & &   M T 4 O R D E R S : : W a i t i n g ( ) )  
  
 # d e f i n e   T O S T R ( A )     # A   +   "   =   "   +   ( s t r i n g ) ( A )   +   " \ n "  
 # d e f i n e   T O S T R 2 ( A )   # A   +   "   =   "   +   E n u m T o S t r i n g ( A )   +   "   ( "   +   ( s t r i n g ) ( A )   +   " ) \ n "  
  
     s t a t i c   v o i d   G e t H i s t o r y P o s i t i o n D a t a (   c o n s t   u l o n g   T i c k e t   )  
     {  
         M T 4 O R D E R S : : O r d e r . T i c k e t   =   ( l o n g ) T i c k e t ;  
         M T 4 O R D E R S : : O r d e r . T i c k e t I D   =   : : H i s t o r y D e a l G e t I n t e g e r ( M T 4 O R D E R S : : O r d e r . T i c k e t ,   D E A L _ P O S I T I O N _ I D ) ;  
         M T 4 O R D E R S : : O r d e r . T y p e   =   ( i n t ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ T Y P E ) ;  
  
         i f   ( ( M T 4 O R D E R S : : O r d e r . T y p e   >   O P _ S E L L ) )  
             M T 4 O R D E R S : : O r d e r . T y p e   + =   ( O P _ B A L A N C E   -   O P _ S E L L   -   1 ) ;  
         e l s e  
             M T 4 O R D E R S : : O r d e r . T y p e   =   1   -   M T 4 O R D E R S : : O r d e r . T y p e ;  
  
         M T 4 O R D E R S : : O r d e r . L o t s   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ V O L U M E ) ;  
  
         M T 4 O R D E R S : : O r d e r . S y m b o l   =   : : H i s t o r y D e a l G e t S t r i n g ( T i c k e t ,   D E A L _ S Y M B O L ) ;  
         M T 4 O R D E R S : : O r d e r . C o m m e n t   =   : : H i s t o r y D e a l G e t S t r i n g ( T i c k e t ,   D E A L _ C O M M E N T ) ;  
  
         M T 4 O R D E R S : : O r d e r . C l o s e T i m e M s c   =   : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ T I M E _ M S C ) ;  
         M T 4 O R D E R S : : O r d e r . C l o s e T i m e   =   ( d a t e t i m e ) ( M T 4 O R D E R S : : O r d e r . C l o s e T i m e M s c   /   1 0 0 0 ) ;   / /   ( d a t e t i m e ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ T I M E ) ;  
  
         M T 4 O R D E R S : : O r d e r . C l o s e P r i c e   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ P R I C E ) ;  
  
         M T 4 O R D E R S : : O r d e r . C l o s e R e a s o n   =   ( E N U M _ D E A L _ R E A S O N ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ R E A S O N ) ; ;  
  
         M T 4 O R D E R S : : O r d e r . E x p i r a t i o n   =   0 ;  
  
         M T 4 O R D E R S : : O r d e r . M a g i c N u m b e r   =   : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ M A G I C ) ;  
  
         M T 4 O R D E R S : : O r d e r . P r o f i t   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ P R O F I T ) ;  
  
         M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ C O M M I S S I O N ) ;  
         M T 4 O R D E R S : : O r d e r . S w a p   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ S W A P ) ;  
  
 # i f n d e f   M T 4 O R D E R S _ S L T P _ O L D  
         M T 4 O R D E R S : : O r d e r . S t o p L o s s   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ S L ) ;  
         M T 4 O R D E R S : : O r d e r . T a k e P r o f i t   =   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ T P ) ;  
 # e l s e   / /   M T 4 O R D E R S _ S L T P _ O L D  
         M T 4 O R D E R S : : O r d e r . S t o p L o s s   =   0 ;  
         M T 4 O R D E R S : : O r d e r . T a k e P r o f i t   =   0 ;  
 # e n d i f   / /   M T 4 O R D E R S _ S L T P _ O L D  
  
         c o n s t   u l o n g   O r d e r T i c k e t   =   : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ O R D E R ) ;  
         c o n s t   u l o n g   P o s T i c k e t   =   M T 4 O R D E R S : : O r d e r . T i c k e t I D ;  
         c o n s t   u l o n g   O p e n T i c k e t   =   ( O r d e r T i c k e t   >   0 )   ?   M T 4 O R D E R S : : H i s t o r y . G e t P o s i t i o n D e a l I n ( P o s T i c k e t )   :   0 ;  
  
         i f   ( O p e n T i c k e t   >   0 )  
         {  
             c o n s t   E N U M _ D E A L _ R E A S O N   R e a s o n   =   ( E N U M _ D E A L _ R E A S O N ) H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ R E A S O N ) ;  
             c o n s t   E N U M _ D E A L _ E N T R Y   D e a l E n t r y   =   ( E N U M _ D E A L _ E N T R Y ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ E N T R Y ) ;  
  
         / /   H i s t o r y   ( O p e n T i c k e t   a n d   O r d e r T i c k e t )   i s   l o a d e d   d u e   t o   G e t P o s i t i o n D e a l I n ,   -   H i s t o r y S e l e c t B y P o s i t i o n  
         # i f d e f   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
             c o n s t   b o o l   R e s   =   t r u e ;  
         # e l s e   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
             / /   P a r t i a l   e x e c u t i o n   w i l l   g e n e r a t e   t h e   n e c e s s a r y   o r d e r   -   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 2 2 7 4 2 3 / p a g e 2 # c o m m e n t _ 6 5 4 3 1 2 9  
             b o o l   R e s   =   M T 4 O R D E R S : : I s T e s t e r   ?   M T 4 O R D E R S : : H i s t o r y S e l e c t O r d e r ( O r d e r T i c k e t )   :   M T 4 O R D E R S : : W a i t i n g ( t r u e ) ;  
  
             i f   ( ! R e s )  
                 W H I L E ( M T 4 O R D E R S : : H i s t o r y S e l e c t O r d e r ( O r d e r T i c k e t ) )   / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 3 0 4 2 3 9 # c o m m e n t _ 1 0 7 1 0 4 0 3  
                     ;  
  
             i f   ( M T 4 O R D E R S : : H i s t o r y S e l e c t D e a l ( O p e n T i c k e t ) )   / /   I t   w i l l   s u r e l y   w o r k ,   s i n c e   O p e n T i c k e t   i s   r e l i a b l y   i n   h i s t o r y .  
         # e n d i f   / /   M T 4 O R D E R S _ F A S T H I S T O R Y _ O F F  
             {  
                 M T 4 O R D E R S : : O r d e r . T i c k e t O p e n   =   ( l o n g ) O p e n T i c k e t ;  
  
                 M T 4 O R D E R S : : O r d e r . O p e n R e a s o n   =   R e a s o n ;  
  
                 M T 4 O R D E R S : : O r d e r . O p e n P r i c e   =   : : H i s t o r y D e a l G e t D o u b l e ( O p e n T i c k e t ,   D E A L _ P R I C E ) ;  
  
                 M T 4 O R D E R S : : O r d e r . O p e n T i m e M s c   =   : : H i s t o r y D e a l G e t I n t e g e r ( O p e n T i c k e t ,   D E A L _ T I M E _ M S C ) ;  
                 M T 4 O R D E R S : : O r d e r . O p e n T i m e   =   ( d a t e t i m e ) ( M T 4 O R D E R S : : O r d e r . O p e n T i m e M s c   /   1 0 0 0 ) ;  
  
                 c o n s t   d o u b l e   O p e n L o t s   =   : : H i s t o r y D e a l G e t D o u b l e ( O p e n T i c k e t ,   D E A L _ V O L U M E ) ;  
  
                 i f   ( O p e n L o t s   >   0 )  
                     M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   + =   : : H i s t o r y D e a l G e t D o u b l e ( O p e n T i c k e t ,   D E A L _ C O M M I S S I O N )   *   M T 4 O R D E R S : : O r d e r . L o t s   /   O p e n L o t s ;  
  
 / /                 i f   ( ! M T 4 O R D E R S : : O r d e r . M a g i c N u m b e r )   / /   M a g i c   n u m b e r   o f   a   c l o s e d   p o s i t i o n   m u s t   a l w a y s   b e   e q u a l   t o   t h a t   o f   t h e   o p e n i n g   d e a l .  
                     c o n s t   l o n g   M a g i c   =   : : H i s t o r y D e a l G e t I n t e g e r ( O p e n T i c k e t ,   D E A L _ M A G I C ) ;  
  
                     i f   ( M a g i c )  
                         M T 4 O R D E R S : : O r d e r . M a g i c N u m b e r   =   M a g i c ;  
  
 / /                 i f   ( M T 4 O R D E R S : : O r d e r . C o m m e n t   = =   " " )   / /   C o m m e n t   o n   a   c l o s e d   p o s i t i o n   m u s t   a l w a y s   b e   e q u a l   t o   t h a t   o n   t h e   o p e n i n g   d e a l .  
                     c o n s t   s t r i n g   S t r C o m m e n t   =   : : H i s t o r y D e a l G e t S t r i n g ( O p e n T i c k e t ,   D E A L _ C O M M E N T ) ;  
  
                     i f   ( S t r C o m m e n t   ! =   " " )  
                         M T 4 O R D E R S : : O r d e r . C o m m e n t   =   S t r C o m m e n t ;  
  
                 i f   ( R e s )   / /   O r d e r T i c k e t   m a y   b e   a b s e n t   i n   h i s t o r y ,   b u t   i t   m a y   b e   f o u n d   a m o n g   t h o s e   s t i l l   a l i v e .   I t   i s   p r o b a b l y   r e a s o n a b l e   t o   w h e e d l e   i n f o   o u t   o f   t h e r e .  
                 {  
             # i f d e f   M T 4 O R D E R S _ S L T P _ O L D  
                     / /   R e v e r s e d   -   n o t   a n   e r r o r :   s e e   O r d e r C l o s e .  
                     M T 4 O R D E R S : : O r d e r . S t o p L o s s   =   : : H i s t o r y O r d e r G e t D o u b l e ( O r d e r T i c k e t ,   ( R e a s o n   = =   D E A L _ R E A S O N _ S L )   ?   O R D E R _ P R I C E _ O P E N   :   O R D E R _ T P ) ;  
                     M T 4 O R D E R S : : O r d e r . T a k e P r o f i t   =   : : H i s t o r y O r d e r G e t D o u b l e ( O r d e r T i c k e t ,   ( R e a s o n   = =   D E A L _ R E A S O N _ T P )   ?   O R D E R _ P R I C E _ O P E N   :   O R D E R _ S L ) ;  
             # e n d i f   / /   M T 4 O R D E R S _ S L T P _ O L D  
  
                     M T 4 O R D E R S : : O r d e r . S t a t e   =   ( E N U M _ O R D E R _ S T A T E ) : : H i s t o r y O r d e r G e t I n t e g e r ( O r d e r T i c k e t ,   O R D E R _ S T A T E ) ;  
  
                     i f   ( ! ( M T 4 O R D E R S : : O r d e r . C l o s e P r i c e R e q u e s t   =   ( D e a l E n t r y   = =   D E A L _ E N T R Y _ O U T _ B Y )   ?  
                                                                                                           M T 4 O R D E R S : : O r d e r . C l o s e P r i c e   :   : : H i s t o r y O r d e r G e t D o u b l e ( O r d e r T i c k e t ,   O R D E R _ P R I C E _ O P E N ) ) )  
                         M T 4 O R D E R S : : O r d e r . C l o s e P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . C l o s e P r i c e ;  
  
                     i f   ( ! ( M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   ( M T 4 O R D E R S : : H i s t o r y S e l e c t O r d e r ( P o s T i c k e t )   & &  
                                                                                                         / /     =C6=0  ;8  MB0  ?@>25@:0?  
                                                                                                         ( M T 4 O R D E R S : : I s T e s t e r   | |   ( : : H i s t o r y D e a l G e t I n t e g e r ( O p e n T i c k e t ,   D E A L _ T I M E _ M S C )   = =   : : H i s t o r y O r d e r G e t I n t e g e r ( P o s T i c k e t ,   O R D E R _ T I M E _ D O N E _ M S C ) ) ) )   ?  
                                                                                                       : : H i s t o r y O r d e r G e t D o u b l e ( P o s T i c k e t ,   O R D E R _ P R I C E _ O P E N )   :   M T 4 O R D E R S : : O r d e r . O p e n P r i c e ) )  
                         M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . O p e n P r i c e ;  
                 }  
                 e l s e  
                 {  
                     M T 4 O R D E R S : : O r d e r . S t a t e   =   O R D E R _ S T A T E _ F I L L E D ;  
  
                     M T 4 O R D E R S : : O r d e r . C l o s e P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . C l o s e P r i c e ;  
                     M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . O p e n P r i c e ;  
                 }  
             }  
  
             i f   ( ! R e s )  
             {  
                 : : A l e r t ( " H i s t o r y O r d e r S e l e c t ( "   +   ( s t r i n g ) O r d e r T i c k e t   +   " )   -   B U G !   M T 4 O R D E R S   -   n o t   S y n c   w i t h   H i s t o r y ! " ) ;  
                 M T 4 O R D E R S : : A l e r t L o g ( ) ;  
  
                 : : P r i n t ( T O S T R ( _ _ F I L E _ _ )   +   " V e r s i o n   =   "   +   ( s t r i n g ) _ _ M T 4 O R D E R S _ _   +   " \ n "   +   T O S T R ( _ _ M Q L B U I L D _ _ )   +   T O S T R ( _ _ D A T E _ _ )   +  
                                 T O S T R ( : : A c c o u n t I n f o S t r i n g ( A C C O U N T _ S E R V E R ) )   +   T O S T R 2 ( ( E N U M _ A C C O U N T _ T R A D E _ M O D E ) : : A c c o u n t I n f o I n t e g e r ( A C C O U N T _ T R A D E _ M O D E ) )   +  
                                 T O S T R ( ( b o o l ) : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ C O N N E C T E D ) )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ P I N G _ L A S T ) )   +   T O S T R ( : : T e r m i n a l I n f o D o u b l e ( T E R M I N A L _ R E T R A N S M I S S I O N ) )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ B U I L D ) )   +   T O S T R ( ( b o o l ) : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ X 6 4 ) )   +  
                                 T O S T R ( ( b o o l ) : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ V P S ) )   +   T O S T R 2 ( ( E N U M _ P R O G R A M _ T Y P E ) : : M Q L I n f o I n t e g e r ( M Q L _ P R O G R A M _ T Y P E ) )   +  
                                 T O S T R ( : : T i m e C u r r e n t ( ) )   +   T O S T R ( : : T i m e T r a d e S e r v e r ( ) )   +   T O S T R ( M T 4 O R D E R S : : T i m e T o S t r i n g ( M T 4 O R D E R S : : G e t T i m e C u r r e n t ( ) ) )   +  
                                 T O S T R ( : : S y m b o l I n f o S t r i n g ( M T 4 O R D E R S : : O r d e r . S y m b o l ,   S Y M B O L _ P A T H ) )   +   T O S T R ( : : S y m b o l I n f o S t r i n g ( M T 4 O R D E R S : : O r d e r . S y m b o l ,   S Y M B O L _ D E S C R I P T I O N ) )   +  
                                 " C u r r e n t T i c k   = "   +   M T 4 O R D E R S : : T i c k T o S t r i n g ( M T 4 O R D E R S : : O r d e r . S y m b o l )   +   " \ n "   +  
                                 T O S T R ( : : P o s i t i o n s T o t a l ( ) )   +   T O S T R ( : : O r d e r s T o t a l ( ) )   +  
                                 T O S T R ( : : H i s t o r y S e l e c t ( 0 ,   I N T _ M A X ) )   +   T O S T R ( : : H i s t o r y D e a l s T o t a l ( ) )   +   T O S T R ( : : H i s t o r y O r d e r s T o t a l ( ) )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ A V A I L A B L E ) )   +   T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ P H Y S I C A L ) )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ T O T A L ) )   +   T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ U S E D ) )   +  
                                 T O S T R ( : : M Q L I n f o I n t e g e r ( M Q L _ M E M O R Y _ L I M I T ) )   +   T O S T R ( : : M Q L I n f o I n t e g e r ( M Q L _ M E M O R Y _ U S E D ) )   +  
                                 T O S T R ( T i c k e t )   +   T O S T R ( O r d e r T i c k e t )   +   T O S T R ( O p e n T i c k e t )   +   T O S T R ( P o s T i c k e t )   +  
                                 T O S T R ( M T 4 O R D E R S : : T i m e T o S t r i n g ( M T 4 O R D E R S : : O r d e r . C l o s e T i m e M s c ) )   +  
                                 T O S T R ( M T 4 O R D E R S : : H i s t o r y S e l e c t O r d e r ( O r d e r T i c k e t ) )   +   T O S T R ( : : O r d e r S e l e c t ( O r d e r T i c k e t ) )   +  
                                 ( : : O r d e r S e l e c t ( O r d e r T i c k e t )   ?   T O S T R 2 ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E ) )   :   N U L L )   +  
                                 ( : : H i s t o r y D e a l s T o t a l ( )   ?   T O S T R ( : : H i s t o r y D e a l G e t T i c k e t ( : : H i s t o r y D e a l s T o t a l ( )   -   1 ) )   +  
                                       " D E A L _ T I M E _ M S C   =   "   +   M T 4 O R D E R S : : T i m e T o S t r i n g ( : : H i s t o r y D e a l G e t I n t e g e r ( : : H i s t o r y D e a l G e t T i c k e t ( : : H i s t o r y D e a l s T o t a l ( )   -   1 ) ,   D E A L _ T I M E _ M S C ) )   +   " \ n "  
                                                                               :   N U L L )   +  
                                 ( : : H i s t o r y O r d e r s T o t a l ( )   ?   T O S T R ( : : H i s t o r y O r d e r G e t T i c k e t ( : : H i s t o r y O r d e r s T o t a l ( )   -   1 ) )   +  
                                       " O R D E R _ T I M E _ D O N E _ M S C   =   "   +   M T 4 O R D E R S : : T i m e T o S t r i n g ( : : H i s t o r y O r d e r G e t I n t e g e r ( : : H i s t o r y O r d e r G e t T i c k e t ( : : H i s t o r y O r d e r s T o t a l ( )   -   1 ) ,   O R D E R _ T I M E _ D O N E _ M S C ) )   +   " \ n "  
                                                                                 :   N U L L ) ) ;  
             }  
         }  
         e l s e  
         {  
             M T 4 O R D E R S : : O r d e r . T i c k e t O p e n   =   M T 4 O R D E R S : : O r d e r . T i c k e t ;  
  
             i f   ( ! M T 4 O R D E R S : : O r d e r . T i c k e t I D )  
                 M T 4 O R D E R S : : O r d e r . T i c k e t I D   =   M T 4 O R D E R S : : O r d e r . T i c k e t ;  
  
             M T 4 O R D E R S : : O r d e r . O p e n P r i c e   =   M T 4 O R D E R S : : O r d e r . C l o s e P r i c e ;   / /   : : H i s t o r y D e a l G e t D o u b l e ( T i c k e t ,   D E A L _ P R I C E ) ;  
  
             M T 4 O R D E R S : : O r d e r . O p e n T i m e M s c   =   M T 4 O R D E R S : : O r d e r . C l o s e T i m e M s c ;  
             M T 4 O R D E R S : : O r d e r . O p e n T i m e   =   M T 4 O R D E R S : : O r d e r . C l o s e T i m e ;       / /   ( d a t e t i m e ) : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ T I M E ) ;  
  
             M T 4 O R D E R S : : O r d e r . O p e n R e a s o n   =   M T 4 O R D E R S : : O r d e r . C l o s e R e a s o n ;  
  
             M T 4 O R D E R S : : O r d e r . S t a t e   =   O R D E R _ S T A T E _ F I L L E D ;  
  
             M T 4 O R D E R S : : O r d e r . C l o s e P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . C l o s e P r i c e ;  
             M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . O p e n P r i c e ;  
         }  
  
         b o o l   R e s   =   M T 4 O R D E R S : : I s T e s t e r   ?   M T 4 O R D E R S : : H i s t o r y S e l e c t O r d e r ( O r d e r T i c k e t )   :   M T 4 O R D E R S : : W a i t i n g ( t r u e ) ;  
  
         i f   ( ! R e s )  
             W H I L E ( M T 4 O R D E R S : : H i s t o r y S e l e c t O r d e r ( O r d e r T i c k e t ) )   / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 3 0 4 2 3 9 # c o m m e n t _ 1 0 7 1 0 4 0 3  
                 ;  
  
         i f   ( ( E N U M _ O R D E R _ T Y P E ) : : H i s t o r y O r d e r G e t I n t e g e r ( O r d e r T i c k e t ,   O R D E R _ T Y P E )   = =   O R D E R _ T Y P E _ C L O S E _ B Y )  
         {  
             c o n s t   u l o n g   P o s T i c k e t B y   =   : : H i s t o r y O r d e r G e t I n t e g e r ( O r d e r T i c k e t ,   O R D E R _ P O S I T I O N _ B Y _ I D ) ;  
  
             i f   ( P o s T i c k e t B y   = =   P o s T i c k e t )   / /   C l o s e B y - S l a v e   s h o u l d   n o t   a f f e c t   t h e   t o t a l   t r a d e .  
             {  
                 M T 4 O R D E R S : : O r d e r . L o t s   =   0 ;  
                 M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   =   0 ;  
  
                 M T 4 O R D E R S : : O r d e r . C l o s e P r i c e   =   M T 4 O R D E R S : : O r d e r . O p e n P r i c e ;  
                 M T 4 O R D E R S : : O r d e r . C l o s e P r i c e R e q u e s t   =   M T 4 O R D E R S : : O r d e r . C l o s e P r i c e ;  
             }  
             e l s e   / /   C l o s e B y - M a s t e r   m u s t   r e c e i v e   a   c o m m i s s i o n   f r o m   C l o s e B y - S l a v e .  
             {  
                 c o n s t   u l o n g   O p e n T i c k e t B y   =   ( O r d e r T i c k e t   >   0 )   ?   M T 4 O R D E R S : : H i s t o r y . G e t P o s i t i o n D e a l I n ( P o s T i c k e t B y )   :   0 ;  
  
                 i f   ( ( O p e n T i c k e t B y   >   0 )   & &   M T 4 O R D E R S : : H i s t o r y S e l e c t D e a l ( O p e n T i c k e t B y ) )  
                 {  
                     c o n s t   d o u b l e   O p e n L o t s   =   : : H i s t o r y D e a l G e t D o u b l e ( O p e n T i c k e t B y ,   D E A L _ V O L U M E ) ;  
  
                     i f   ( O p e n L o t s   >   0 )  
                         M T 4 O R D E R S : : O r d e r . C o m m i s s i o n   + =   : : H i s t o r y D e a l G e t D o u b l e ( O p e n T i c k e t B y ,   D E A L _ C O M M I S S I O N )   *   M T 4 O R D E R S : : O r d e r . L o t s   /   O p e n L o t s ;  
                 }  
             }  
         }  
  
         r e t u r n ;  
     }  
  
     s t a t i c   b o o l   W a i t i n g (   c o n s t   b o o l   F l a g I n i t   =   f a l s e   )  
     {  
         s t a t i c   u l o n g   S t a r t T i m e   =   0 ;  
  
         c o n s t   b o o l   R e s   =   F l a g I n i t   ?   f a l s e   :   ( : : G e t M i c r o s e c o n d C o u n t ( )   -   S t a r t T i m e   <   M T 4 O R D E R S : : O r d e r S e n d _ M a x P a u s e ) ;  
  
         i f   ( F l a g I n i t )  
         {  
             S t a r t T i m e   =   : : G e t M i c r o s e c o n d C o u n t ( ) ;  
  
             M T 4 O R D E R S : : O r d e r S e n d B u g   =   0 ;  
         }  
         e l s e   i f   ( R e s )  
         {  
 / /             : : S l e e p ( 0 ) ;   / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 1 7 0 9 5 2 / p a g e 1 0 0 # c o m m e n t _ 8 7 5 0 5 1 1  
  
             M T 4 O R D E R S : : O r d e r S e n d B u g + + ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   E q u a l P r i c e s (   c o n s t   d o u b l e   P r i c e 1 ,   c o n s t   d o u b l e   & P r i c e 2 ,   c o n s t   i n t   & d i g i t s )  
     {  
         r e t u r n ( ! : : N o r m a l i z e D o u b l e ( P r i c e 1   -   P r i c e 2 ,   d i g i t s ) ) ;  
     }  
  
     s t a t i c   b o o l   H i s t o r y D e a l S e l e c t (   M q l T r a d e R e s u l t   & R e s u l t   )  
     {  
         / /   0<5=8BL  H i s t o r y S e l e c t B y P o s i t i o n   =0  H i s t o r y S e l e c t ( P o s T i m e ,   P o s T i m e )  
         i f   ( ! R e s u l t . d e a l   & &   R e s u l t . o r d e r   & &   : : H i s t o r y S e l e c t B y P o s i t i o n ( : : H i s t o r y O r d e r G e t I n t e g e r ( R e s u l t . o r d e r ,   O R D E R _ P O S I T I O N _ I D ) ) )  
             f o r   ( i n t   i   =   : : H i s t o r y D e a l s T o t a l ( )   -   1 ;   i   > =   0 ;   i - - )  
             {  
                 c o n s t   u l o n g   D e a l T i c k e t   =   : : H i s t o r y D e a l G e t T i c k e t ( i ) ;  
  
                 i f   ( R e s u l t . o r d e r   = =   : : H i s t o r y D e a l G e t I n t e g e r ( D e a l T i c k e t ,   D E A L _ O R D E R ) )  
                 {  
                     R e s u l t . d e a l   =   D e a l T i c k e t ;  
                     R e s u l t . p r i c e   =   : : H i s t o r y D e a l G e t D o u b l e ( D e a l T i c k e t ,   D E A L _ P R I C E ) ;  
  
                     b r e a k ;  
                 }  
             }  
  
         r e t u r n ( : : H i s t o r y D e a l S e l e c t ( R e s u l t . d e a l ) ) ;  
     }  
  
 / *  
 # d e f i n e   M T 4 O R D E R S _ B E N C H M A R K   A l e r t ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l   +   "   "   +               \  
                                                                     ( s t r i n g ) M T 4 O R D E R S : : L a s t T r a d e R e s u l t . o r d e r   +   "   "   +   \  
                                                                     M T 4 O R D E R S : : L a s t T r a d e R e s u l t . c o m m e n t ) ;                           \  
                                                         P r i n t ( T o S t r i n g ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t )   +                     \  
                                                                     T o S t r i n g ( M T 4 O R D E R S : : L a s t T r a d e R e s u l t ) ) ;  
 * /  
  
 # d e f i n e   T M P _ M T 4 O R D E R S _ B E N C H M A R K ( A )   \  
     s t a t i c   u l o n g   M a x # # A   =   0 ;                   \  
                                                                       \  
     i f   ( I n t e r v a l # # A   >   M a x # # A )                 \  
     {                                                                 \  
         M T 4 O R D E R S _ B E N C H M A R K                         \  
                                                                       \  
         M a x # # A   =   I n t e r v a l # # A ;                     \  
     }  
  
     s t a t i c   v o i d   O r d e r S e n d _ B e n c h m a r k (   c o n s t   u l o n g   & I n t e r v a l 1 ,   c o n s t   u l o n g   & I n t e r v a l 2   )  
     {  
         # i f d e f   M T 4 O R D E R S _ B E N C H M A R K  
             T M P _ M T 4 O R D E R S _ B E N C H M A R K ( 1 )  
             T M P _ M T 4 O R D E R S _ B E N C H M A R K ( 2 )  
         # e n d i f   / /   M T 4 O R D E R S _ B E N C H M A R K  
  
         r e t u r n ;  
     }  
  
 # u n d e f   T M P _ M T 4 O R D E R S _ B E N C H M A R K  
  
     s t a t i c   s t r i n g   T o S t r i n g (   c o n s t   M q l T r a d e R e q u e s t   & R e q u e s t   )  
     {  
         r e t u r n ( T O S T R 2 ( R e q u e s t . a c t i o n )   +   T O S T R ( R e q u e s t . m a g i c )   +   T O S T R ( R e q u e s t . o r d e r )   +  
                       T O S T R ( R e q u e s t . s y m b o l )   +   T O S T R ( R e q u e s t . v o l u m e )   +   T O S T R ( R e q u e s t . p r i c e )   +  
                       T O S T R ( R e q u e s t . s t o p l i m i t )   +   T O S T R ( R e q u e s t . s l )   +     T O S T R ( R e q u e s t . t p )   +  
                       T O S T R ( R e q u e s t . d e v i a t i o n )   +   T O S T R 2 ( R e q u e s t . t y p e )   +   T O S T R 2 ( R e q u e s t . t y p e _ f i l l i n g )   +  
                       T O S T R 2 ( R e q u e s t . t y p e _ t i m e )   +   T O S T R ( R e q u e s t . e x p i r a t i o n )   +   T O S T R ( R e q u e s t . c o m m e n t )   +  
                       T O S T R ( R e q u e s t . p o s i t i o n )   +   T O S T R ( R e q u e s t . p o s i t i o n _ b y ) ) ;  
     }  
  
     s t a t i c   s t r i n g   T o S t r i n g (   c o n s t   M q l T r a d e R e s u l t   & R e s u l t   )  
     {  
         r e t u r n ( T O S T R ( R e s u l t . r e t c o d e )   +   T O S T R ( R e s u l t . d e a l )   +   T O S T R ( R e s u l t . o r d e r )   +  
                       T O S T R ( R e s u l t . v o l u m e )   +   T O S T R ( R e s u l t . p r i c e )   +   T O S T R ( R e s u l t . b i d )   +  
                       T O S T R ( R e s u l t . a s k )   +   T O S T R ( R e s u l t . c o m m e n t )   +   T O S T R ( R e s u l t . r e q u e s t _ i d )   +  
                       T O S T R ( R e s u l t . r e t c o d e _ e x t e r n a l ) ) ;  
     }  
  
     s t a t i c   b o o l   O r d e r S e n d (   c o n s t   M q l T r a d e R e q u e s t   & R e q u e s t ,   M q l T r a d e R e s u l t   & R e s u l t   )  
     {  
         M q l T i c k   P r e v T i c k   =   { 0 } ;  
  
         i f   ( ! M T 4 O R D E R S : : I s T e s t e r )  
             : : S y m b o l I n f o T i c k ( R e q u e s t . s y m b o l ,   P r e v T i c k ) ;  
  
         c o n s t   l o n g   P r e v T i m e C u r r e n t   =   M T 4 O R D E R S : : I s T e s t e r   ?   0   :   M T 4 O R D E R S : : G e t T i m e C u r r e n t ( ) ;  
         c o n s t   u l o n g   S t a r t T i m e 1   =   M T 4 O R D E R S : : I s T e s t e r   ?   0   :   : : G e t M i c r o s e c o n d C o u n t ( ) ;  
  
         b o o l   R e s   =   : : O r d e r S e n d ( R e q u e s t ,   R e s u l t ) ;  
  
         c o n s t   u l o n g   I n t e r v a l 1   =   M T 4 O R D E R S : : I s T e s t e r   ?   0   :   ( : : G e t M i c r o s e c o n d C o u n t ( )   -   S t a r t T i m e 1 ) ;  
  
         c o n s t   u l o n g   S t a r t T i m e 2   =   M T 4 O R D E R S : : I s T e s t e r   ?   0   :   : : G e t M i c r o s e c o n d C o u n t ( ) ;  
  
         i f   ( R e s   & &   ! M T 4 O R D E R S : : I s T e s t e r   & &   ( R e s u l t . r e t c o d e   <   T R A D E _ R E T C O D E _ E R R O R )   & &   ( M T 4 O R D E R S : : O r d e r S e n d _ M a x P a u s e   >   0 ) )  
         {  
             R e s   =   ( R e s u l t . r e t c o d e   = =   T R A D E _ R E T C O D E _ D O N E ) ;  
             M T 4 O R D E R S : : W a i t i n g ( t r u e ) ;  
  
             / /   T R A D E _ A C T I O N _ C L O S E _ B Y   i s   n o t   p r e s e n t   i n   t h e   l i s t   o f   c h e c k s  
             i f   ( R e q u e s t . a c t i o n   = =   T R A D E _ A C T I O N _ D E A L )  
             {  
                 i f   ( ! R e s u l t . d e a l )  
                 {  
                     W H I L E ( : : O r d e r S e l e c t ( R e s u l t . o r d e r )   | |   : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) )  
                         ;  
  
                     i f   ( ! R e s )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : O r d e r S e l e c t ( R e s u l t . o r d e r ) )   +   T O S T R ( : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) ) ) ;  
                     e l s e   i f   ( : : O r d e r S e l e c t ( R e s u l t . o r d e r )   & &   ! ( R e s   =   ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E )   = =   O R D E R _ S T A T E _ P L A C E D )   | |  
                                                                                                                     ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E )   = =   O R D E R _ S T A T E _ P A R T I A L ) ) )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : O r d e r S e l e c t ( R e s u l t . o r d e r ) )   +   T O S T R 2 ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E ) ) ) ;  
                 }  
  
                 / /   I f   t h e   r e m a i n i n g   p a r t   i s   s t i l l   h a n g i n g   a f t e r   t h e   p a r t i a l   e x e c u t i o n ,   f a l s e .  
                 i f   ( R e s )  
                 {  
                     c o n s t   b o o l   R e s u l t D e a l   =   ( ! R e s u l t . d e a l )   & &   ( ! M T 4 O R D E R S : : O r d e r S e n d B u g ) ;  
  
                     i f   ( M T 4 O R D E R S : : O r d e r S e n d B u g   & &   ( ! R e s u l t . d e a l ) )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   " B e f o r e   : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) : \ n "   +   T O S T R ( M T 4 O R D E R S : : O r d e r S e n d B u g )   +   T O S T R ( R e s u l t . d e a l ) ) ;  
  
                     W H I L E ( : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) )  
                         ;  
  
                     / /   I f   t h e r e   w a s   n o   O r d e r S e n d   b u g   a n d   t h e r e   w a s   R e s u l t . d e a l   = =   0  
                     i f   ( R e s u l t D e a l )  
                         M T 4 O R D E R S : : O r d e r S e n d B u g   =   0 ;  
  
                     i f   ( ! R e s )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) )   +   T O S T R ( : : H i s t o r y D e a l S e l e c t ( R e s u l t . d e a l ) )   +   T O S T R ( : : O r d e r S e l e c t ( R e s u l t . o r d e r ) ) ) ;  
                     / /   I f   t h e   h i s t o r i c a l   o r d e r   w a s   n o t   e x e c u t e d   ( d u e   t o   r e j e c t i o n ) ,   f a l s e  
                     e l s e   i f   ( ! ( R e s   =   ( ( E N U M _ O R D E R _ S T A T E ) : : H i s t o r y O r d e r G e t I n t e g e r ( R e s u l t . o r d e r ,   O R D E R _ S T A T E )   = =   O R D E R _ S T A T E _ F I L L E D )   | |  
                                                       ( ( E N U M _ O R D E R _ S T A T E ) : : H i s t o r y O r d e r G e t I n t e g e r ( R e s u l t . o r d e r ,   O R D E R _ S T A T E )   = =   O R D E R _ S T A T E _ P A R T I A L ) ) )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R 2 ( ( E N U M _ O R D E R _ S T A T E ) : : H i s t o r y O r d e r G e t I n t e g e r ( R e s u l t . o r d e r ,   O R D E R _ S T A T E ) ) ) ;  
                 }  
  
                 i f   ( R e s )  
                 {  
                     c o n s t   b o o l   R e s u l t D e a l   =   ( ! R e s u l t . d e a l )   & &   ( ! M T 4 O R D E R S : : O r d e r S e n d B u g ) ;  
  
                     i f   ( M T 4 O R D E R S : : O r d e r S e n d B u g   & &   ( ! R e s u l t . d e a l ) )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   " B e f o r e   M T 4 O R D E R S : : H i s t o r y D e a l S e l e c t ( R e s u l t ) : \ n "   +   T O S T R ( M T 4 O R D E R S : : O r d e r S e n d B u g )   +   T O S T R ( R e s u l t . d e a l ) ) ;  
  
                     W H I L E ( M T 4 O R D E R S : : H i s t o r y D e a l S e l e c t ( R e s u l t ) )  
                         ;  
  
                     / /   I f   t h e r e   w a s   n o   O r d e r S e n d   b u g   a n d   t h e r e   w a s   R e s u l t . d e a l   = =   0  
                     i f   ( R e s u l t D e a l )  
                         M T 4 O R D E R S : : O r d e r S e n d B u g   =   0 ;  
  
                     i f   ( ! R e s )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( M T 4 O R D E R S : : H i s t o r y D e a l S e l e c t ( R e s u l t ) ) ) ;  
                 }  
             }  
             e l s e   i f   ( R e q u e s t . a c t i o n   = =   T R A D E _ A C T I O N _ P E N D I N G )  
             {  
                 i f   ( R e s )  
                 {  
                     W H I L E ( : : O r d e r S e l e c t ( R e s u l t . o r d e r ) )  
                         ;  
  
                     i f   ( ! R e s )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : O r d e r S e l e c t ( R e s u l t . o r d e r ) ) ) ;  
                     e l s e   i f   ( ! ( R e s   =   ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E )   = =   O R D E R _ S T A T E _ P L A C E D )   | |  
                                                       ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E )   = =   O R D E R _ S T A T E _ P A R T I A L ) ) )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R 2 ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E ) ) ) ;  
                 }  
                 e l s e  
                 {  
                     W H I L E ( : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) )  
                         ;  
  
                     : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) ) ) ;  
  
                     R e s   =   f a l s e ;  
                 }  
             }  
             e l s e   i f   ( R e q u e s t . a c t i o n   = =   T R A D E _ A C T I O N _ S L T P )  
             {  
                 i f   ( R e s )  
                 {  
                     c o n s t   i n t   d i g i t s   =   ( i n t ) : : S y m b o l I n f o I n t e g e r ( R e q u e s t . s y m b o l ,   S Y M B O L _ D I G I T S ) ;  
  
                     b o o l   E q u a l S L   =   f a l s e ;  
                     b o o l   E q u a l T P   =   f a l s e ;  
  
                     d o  
                         i f   ( R e q u e s t . p o s i t i o n   ?   : : P o s i t i o n S e l e c t B y T i c k e t ( R e q u e s t . p o s i t i o n )   :   : : P o s i t i o n S e l e c t ( R e q u e s t . s y m b o l ) )  
                         {  
                             E q u a l S L   =   M T 4 O R D E R S : : E q u a l P r i c e s ( : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ S L ) ,   R e q u e s t . s l ,   d i g i t s ) ;  
                             E q u a l T P   =   M T 4 O R D E R S : : E q u a l P r i c e s ( : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ T P ) ,   R e q u e s t . t p ,   d i g i t s ) ;  
                         }  
                     W H I L E ( E q u a l S L   & &   E q u a l T P ) ;  
  
                     i f   ( ! R e s )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ S L ) )   +   T O S T R ( : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ T P ) )   +  
                                         T O S T R ( E q u a l S L )   +   T O S T R ( E q u a l T P )   +  
                                         T O S T R ( R e q u e s t . p o s i t i o n   ?   : : P o s i t i o n S e l e c t B y T i c k e t ( R e q u e s t . p o s i t i o n )   :   : : P o s i t i o n S e l e c t ( R e q u e s t . s y m b o l ) ) ) ;  
                 }  
             }  
             e l s e   i f   ( R e q u e s t . a c t i o n   = =   T R A D E _ A C T I O N _ M O D I F Y )  
             {  
                 i f   ( R e s )  
                 {  
                     c o n s t   i n t   d i g i t s   =   ( i n t ) : : S y m b o l I n f o I n t e g e r ( R e q u e s t . s y m b o l ,   S Y M B O L _ D I G I T S ) ;  
  
                     b o o l   E q u a l S L   =   f a l s e ;  
                     b o o l   E q u a l T P   =   f a l s e ;  
                     b o o l   E q u a l P r i c e   =   f a l s e ;  
  
                     d o  
                         i f   ( : : O r d e r S e l e c t ( R e s u l t . o r d e r )   & &   ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E )   ! =   O R D E R _ S T A T E _ R E Q U E S T _ M O D I F Y ) )  
                         {  
                             E q u a l S L   =   M T 4 O R D E R S : : E q u a l P r i c e s ( : : O r d e r G e t D o u b l e ( O R D E R _ S L ) ,   R e q u e s t . s l ,   d i g i t s ) ;  
                             E q u a l T P   =   M T 4 O R D E R S : : E q u a l P r i c e s ( : : O r d e r G e t D o u b l e ( O R D E R _ T P ) ,   R e q u e s t . t p ,   d i g i t s ) ;  
                             E q u a l P r i c e   =   M T 4 O R D E R S : : E q u a l P r i c e s ( : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ O P E N ) ,   R e q u e s t . p r i c e ,   d i g i t s ) ;  
                         }  
                     W H I L E ( ( E q u a l S L   & &   E q u a l T P   & &   E q u a l P r i c e ) ) ;  
  
                     i f   ( ! R e s )  
                         : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : O r d e r G e t D o u b l e ( O R D E R _ S L ) )   +   T O S T R ( R e q u e s t . s l ) +  
                                         T O S T R ( : : O r d e r G e t D o u b l e ( O R D E R _ T P ) )   +   T O S T R ( R e q u e s t . t p )   +  
                                         T O S T R ( : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ O P E N ) )   +   T O S T R ( R e q u e s t . p r i c e )   +  
                                         T O S T R ( E q u a l S L )   +   T O S T R ( E q u a l T P )   +   T O S T R ( E q u a l P r i c e )   +  
                                         T O S T R ( : : O r d e r S e l e c t ( R e s u l t . o r d e r ) )   +  
                                         T O S T R 2 ( ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E ) ) ) ;  
                 }  
             }  
             e l s e   i f   ( R e q u e s t . a c t i o n   = =   T R A D E _ A C T I O N _ R E M O V E )  
             {  
                 i f   ( R e s )  
                     W H I L E ( : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) )  
                         ;  
  
                 i f   ( ! R e s )  
                     : : P r i n t ( " L i n e   =   "   +   ( s t r i n g ) _ _ L I N E _ _   +   " \ n "   +   T O S T R ( : : H i s t o r y O r d e r S e l e c t ( R e s u l t . o r d e r ) ) ) ;  
             }  
  
             c o n s t   u l o n g   I n t e r v a l 2   =   : : G e t M i c r o s e c o n d C o u n t ( )   -   S t a r t T i m e 2 ;  
  
             R e s u l t . c o m m e n t   + =   "   "   +   : : D o u b l e T o S t r i n g ( I n t e r v a l 1   /   1 0 0 0 . 0 ,   3 )   +   "   +   "   +  
                                                             : : D o u b l e T o S t r i n g ( I n t e r v a l 2   /   1 0 0 0 . 0 ,   3 )   +   "   ( "   +   ( s t r i n g ) M T 4 O R D E R S : : O r d e r S e n d B u g   +   " )   m s . " ;  
  
             i f   ( ! R e s   | |   M T 4 O R D E R S : : O r d e r S e n d B u g )  
             {  
                 : : A l e r t ( R e s   ?   " O r d e r S e n d ( "   +   ( s t r i n g ) R e s u l t . o r d e r   +   " )   -   B U G ! "   :   " M T 4 O R D E R S   -   n o t   S y n c   w i t h   H i s t o r y ! " ) ;  
                 M T 4 O R D E R S : : A l e r t L o g ( ) ;  
  
                 : : P r i n t ( T O S T R ( _ _ F I L E _ _ )   +   " V e r s i o n   =   "   +   ( s t r i n g ) _ _ M T 4 O R D E R S _ _   +   " \ n "   +   T O S T R ( _ _ M Q L B U I L D _ _ )   +   T O S T R ( _ _ D A T E _ _ )   +  
                                 T O S T R ( : : A c c o u n t I n f o S t r i n g ( A C C O U N T _ S E R V E R ) )   +   T O S T R 2 ( ( E N U M _ A C C O U N T _ T R A D E _ M O D E ) : : A c c o u n t I n f o I n t e g e r ( A C C O U N T _ T R A D E _ M O D E ) )   +  
                                 T O S T R ( ( b o o l ) : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ C O N N E C T E D ) )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ P I N G _ L A S T ) )   +   T O S T R ( : : T e r m i n a l I n f o D o u b l e ( T E R M I N A L _ R E T R A N S M I S S I O N ) )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ B U I L D ) )   +   T O S T R ( ( b o o l ) : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ X 6 4 ) )   +  
                                 T O S T R ( ( b o o l ) : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ V P S ) )   +   T O S T R 2 ( ( E N U M _ P R O G R A M _ T Y P E ) : : M Q L I n f o I n t e g e r ( M Q L _ P R O G R A M _ T Y P E ) )   +  
                                 T O S T R ( : : T i m e C u r r e n t ( ) )   +   T O S T R ( : : T i m e T r a d e S e r v e r ( ) )   +  
                                 T O S T R ( M T 4 O R D E R S : : T i m e T o S t r i n g ( M T 4 O R D E R S : : G e t T i m e C u r r e n t ( ) ) )   +   T O S T R ( M T 4 O R D E R S : : T i m e T o S t r i n g ( P r e v T i m e C u r r e n t ) )   +  
                                 " P r e v T i c k   = "   +   M T 4 O R D E R S : : T i c k T o S t r i n g ( R e q u e s t . s y m b o l ,   P r e v T i c k )   +   " \ n "   +  
                                 " C u r r e n t T i c k   = "   +   M T 4 O R D E R S : : T i c k T o S t r i n g ( R e q u e s t . s y m b o l )   +   " \ n "   +  
                                 T O S T R ( : : S y m b o l I n f o S t r i n g ( R e q u e s t . s y m b o l ,   S Y M B O L _ P A T H ) )   +   T O S T R ( : : S y m b o l I n f o S t r i n g ( R e q u e s t . s y m b o l ,   S Y M B O L _ D E S C R I P T I O N ) )   +  
                                 T O S T R ( : : P o s i t i o n s T o t a l ( ) )   +   T O S T R ( : : O r d e r s T o t a l ( ) )   +  
                                 T O S T R ( : : H i s t o r y S e l e c t ( 0 ,   I N T _ M A X ) )   +   T O S T R ( : : H i s t o r y D e a l s T o t a l ( ) )   +   T O S T R ( : : H i s t o r y O r d e r s T o t a l ( ) )   +  
                                 ( : : H i s t o r y D e a l s T o t a l ( )   ?   T O S T R ( : : H i s t o r y D e a l G e t T i c k e t ( : : H i s t o r y D e a l s T o t a l ( )   -   1 ) )   +  
                                       " D E A L _ T I M E _ M S C   =   "   +   M T 4 O R D E R S : : T i m e T o S t r i n g ( : : H i s t o r y D e a l G e t I n t e g e r ( : : H i s t o r y D e a l G e t T i c k e t ( : : H i s t o r y D e a l s T o t a l ( )   -   1 ) ,   D E A L _ T I M E _ M S C ) )   +   " \ n "  
                                                                               :   N U L L )   +  
                                 ( : : H i s t o r y O r d e r s T o t a l ( )   ?   T O S T R ( : : H i s t o r y O r d e r G e t T i c k e t ( : : H i s t o r y O r d e r s T o t a l ( )   -   1 ) )   +  
                                       " O R D E R _ T I M E _ D O N E _ M S C   =   "   +   M T 4 O R D E R S : : T i m e T o S t r i n g ( : : H i s t o r y O r d e r G e t I n t e g e r ( : : H i s t o r y O r d e r G e t T i c k e t ( : : H i s t o r y O r d e r s T o t a l ( )   -   1 ) ,   O R D E R _ T I M E _ D O N E _ M S C ) )   +   " \ n "  
                                                                                 :   N U L L )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ A V A I L A B L E ) )   +   T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ P H Y S I C A L ) )   +  
                                 T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ T O T A L ) )   +   T O S T R ( : : T e r m i n a l I n f o I n t e g e r ( T E R M I N A L _ M E M O R Y _ U S E D ) )   +  
                                 T O S T R ( : : M Q L I n f o I n t e g e r ( M Q L _ M E M O R Y _ L I M I T ) )   +   T O S T R ( : : M Q L I n f o I n t e g e r ( M Q L _ M E M O R Y _ U S E D ) )   +  
                                 T O S T R ( M T 4 O R D E R S : : I s H e d g i n g )   +   T O S T R ( R e s )   +   T O S T R ( M T 4 O R D E R S : : O r d e r S e n d B u g )   +  
                                 M T 4 O R D E R S : : T o S t r i n g ( R e q u e s t )   +   M T 4 O R D E R S : : T o S t r i n g ( R e s u l t ) ) ;  
             }  
             e l s e  
                 M T 4 O R D E R S : : O r d e r S e n d _ B e n c h m a r k ( I n t e r v a l 1 ,   I n t e r v a l 2 ) ;  
         }  
         e l s e   i f   ( ! M T 4 O R D E R S : : I s T e s t e r )  
         {  
             R e s u l t . c o m m e n t   + =   "   "   +   : : D o u b l e T o S t r i n g ( I n t e r v a l 1   /   1 0 0 0 . 0 ,   3 )   +   "   m s " ;  
  
             : : P r i n t ( T O S T R ( : : T i m e C u r r e n t ( ) )   +   T O S T R ( : : T i m e T r a d e S e r v e r ( ) )   +   T O S T R ( P r e v T i m e C u r r e n t )   +  
                             M T 4 O R D E R S : : T i c k T o S t r i n g ( R e q u e s t . s y m b o l ,   P r e v T i c k )   +   " \ n "   +   M T 4 O R D E R S : : T i c k T o S t r i n g ( R e q u e s t . s y m b o l )   +   " \ n "   +  
                             M T 4 O R D E R S : : T o S t r i n g ( R e q u e s t )   +   M T 4 O R D E R S : : T o S t r i n g ( R e s u l t ) ) ;  
  
 / /             E x p e r t R e m o v e ( ) ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
 # u n d e f   T O S T R 2  
 # u n d e f   T O S T R  
 # u n d e f   W H I L E  
  
     s t a t i c   E N U M _ D A Y _ O F _ W E E K   G e t D a y O f W e e k (   c o n s t   d a t e t i m e   & t i m e   )  
     {  
         M q l D a t e T i m e   s T i m e   =   { 0 } ;  
  
         : : T i m e T o S t r u c t ( t i m e ,   s T i m e ) ;  
  
         r e t u r n ( ( E N U M _ D A Y _ O F _ W E E K ) s T i m e . d a y _ o f _ w e e k ) ;  
     }  
  
     s t a t i c   b o o l   S e s s i o n T r a d e (   c o n s t   s t r i n g   & S y m b   )  
     {  
         d a t e t i m e   T i m e N o w   =   : : T i m e C u r r e n t ( ) ;  
  
         c o n s t   E N U M _ D A Y _ O F _ W E E K   D a y O f W e e k   =   M T 4 O R D E R S : : G e t D a y O f W e e k ( T i m e N o w ) ;  
  
         T i m e N o w   % =   2 4   *   6 0   *   6 0 ;  
  
         b o o l   R e s   =   f a l s e ;  
         d a t e t i m e   F r o m ,   T o ;  
  
         f o r   ( i n t   i   =   0 ;   ( ! R e s )   & &   : : S y m b o l I n f o S e s s i o n T r a d e ( S y m b ,   D a y O f W e e k ,   i ,   F r o m ,   T o ) ;   i + + )  
             R e s   =   ( ( F r o m   < =   T i m e N o w )   & &   ( T i m e N o w   <   T o ) ) ;  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   S y m b o l T r a d e (   c o n s t   s t r i n g   & S y m b   )  
     {  
         M q l T i c k   T i c k ;  
  
         r e t u r n ( : : S y m b o l I n f o T i c k ( S y m b ,   T i c k )   ?   ( T i c k . b i d   & &   T i c k . a s k   & &   M T 4 O R D E R S : : S e s s i o n T r a d e ( S y m b )   / *   & &  
                       ( ( E N U M _ S Y M B O L _ T R A D E _ M O D E ) : : S y m b o l I n f o I n t e g e r ( S y m b ,   S Y M B O L _ T R A D E _ M O D E )   = =   S Y M B O L _ T R A D E _ M O D E _ F U L L )   * / )   :   f a l s e ) ;  
     }  
  
     s t a t i c   b o o l   C o r r e c t R e s u l t (   v o i d   )  
     {  
         : : Z e r o M e m o r y ( M T 4 O R D E R S : : L a s t T r a d e R e s u l t ) ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e s u l t . r e t c o d e   =   M T 4 O R D E R S : : L a s t T r a d e C h e c k R e s u l t . r e t c o d e ;  
         M T 4 O R D E R S : : L a s t T r a d e R e s u l t . c o m m e n t   =   M T 4 O R D E R S : : L a s t T r a d e C h e c k R e s u l t . c o m m e n t ;  
  
         r e t u r n ( f a l s e ) ;  
     }  
  
     s t a t i c   b o o l   N e w O r d e r C h e c k (   v o i d   )  
     {  
         r e t u r n ( ( : : O r d e r C h e c k ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ,   M T 4 O R D E R S : : L a s t T r a d e C h e c k R e s u l t )   & &  
                       ( M T 4 O R D E R S : : I s T e s t e r   | |   M T 4 O R D E R S : : S y m b o l T r a d e ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l ) ) )   | |  
                       ( ! M T 4 O R D E R S : : I s T e s t e r   & &   M T 4 O R D E R S : : C o r r e c t R e s u l t ( ) ) ) ;  
     }  
  
     s t a t i c   b o o l   N e w O r d e r S e n d (   c o n s t   i n t   & C h e c k   )  
     {  
         r e t u r n ( ( C h e c k   = =   I N T _ M A X )   ?   M T 4 O R D E R S : : N e w O r d e r C h e c k ( )   :  
                       ( ( ( C h e c k   ! =   I N T _ M I N )   | |   M T 4 O R D E R S : : N e w O r d e r C h e c k ( ) )   & &   M T 4 O R D E R S : : O r d e r S e n d ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ,   M T 4 O R D E R S : : L a s t T r a d e R e s u l t )   ?   M T 4 O R D E R S : : L a s t T r a d e R e s u l t . r e t c o d e   <   T R A D E _ R E T C O D E _ E R R O R   :   f a l s e ) ) ;  
     }  
  
     s t a t i c   b o o l   M o d i f y P o s i t i o n (   c o n s t   l o n g   & T i c k e t ,   M q l T r a d e R e q u e s t   & R e q u e s t   )  
     {  
         c o n s t   b o o l   R e s   =   : : P o s i t i o n S e l e c t B y T i c k e t ( T i c k e t ) ;  
  
         i f   ( R e s )  
         {  
             R e q u e s t . a c t i o n   =   T R A D E _ A C T I O N _ S L T P ;  
  
             R e q u e s t . p o s i t i o n   =   T i c k e t ;  
             R e q u e s t . s y m b o l   =   : : P o s i t i o n G e t S t r i n g ( P O S I T I O N _ S Y M B O L ) ;   / /   s p e c i f y i n g   t h e   t i c k e t   a l o n e   i s   n o t   s u f f i c i e n t !  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   E N U M _ O R D E R _ T Y P E _ F I L L I N G   G e t F i l l i n g (   c o n s t   s t r i n g   & S y m b ,   c o n s t   u i n t   T y p e   =   O R D E R _ F I L L I N G _ F O K   )  
     {  
         s t a t i c   E N U M _ O R D E R _ T Y P E _ F I L L I N G   R e s   =   O R D E R _ F I L L I N G _ F O K ;  
         s t a t i c   s t r i n g   L a s t S y m b   =   N U L L ;  
         s t a t i c   u i n t   L a s t T y p e   =   O R D E R _ F I L L I N G _ F O K ;  
  
         c o n s t   b o o l   S y m b F l a g   =   ( L a s t S y m b   ! =   S y m b ) ;  
  
         i f   ( S y m b F l a g   | |   ( L a s t T y p e   ! =   T y p e ) )   / /   I t   c a n   b e   l i g h t l y   a c c e l e r a r e d   b y   c h a n g i n g   t h e   s e q u e n c e   o f   c h e c k i n g   t h e   c o n d i t i o n .  
         {  
             L a s t T y p e   =   T y p e ;  
  
             i f   ( S y m b F l a g )  
                 L a s t S y m b   =   S y m b ;  
  
             c o n s t   E N U M _ S Y M B O L _ T R A D E _ E X E C U T I O N   E x e M o d e   =   ( E N U M _ S Y M B O L _ T R A D E _ E X E C U T I O N ) : : S y m b o l I n f o I n t e g e r ( S y m b ,   S Y M B O L _ T R A D E _ E X E M O D E ) ;  
             c o n s t   i n t   F i l l i n g M o d e   =   ( i n t ) : : S y m b o l I n f o I n t e g e r ( S y m b ,   S Y M B O L _ F I L L I N G _ M O D E ) ;  
  
             R e s   =   ( ! F i l l i n g M o d e   | |   ( T y p e   > =   O R D E R _ F I L L I N G _ R E T U R N )   | |   ( ( F i l l i n g M o d e   &   ( T y p e   +   1 ) )   ! =   T y p e   +   1 ) )   ?  
                         ( ( ( E x e M o d e   = =   S Y M B O L _ T R A D E _ E X E C U T I O N _ E X C H A N G E )   | |   ( E x e M o d e   = =   S Y M B O L _ T R A D E _ E X E C U T I O N _ I N S T A N T ) )   ?  
                           O R D E R _ F I L L I N G _ R E T U R N   :   ( ( F i l l i n g M o d e   = =   S Y M B O L _ F I L L I N G _ I O C )   ?   O R D E R _ F I L L I N G _ I O C   :   O R D E R _ F I L L I N G _ F O K ) )   :  
                         ( E N U M _ O R D E R _ T Y P E _ F I L L I N G ) T y p e ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   E N U M _ O R D E R _ T Y P E _ T I M E   G e t E x p i r a t i o n T y p e (   c o n s t   s t r i n g   & S y m b ,   u i n t   E x p i r a t i o n   =   O R D E R _ T I M E _ G T C   )  
     {  
         s t a t i c   E N U M _ O R D E R _ T Y P E _ T I M E   R e s   =   O R D E R _ T I M E _ G T C ;  
         s t a t i c   s t r i n g   L a s t S y m b   =   N U L L ;  
         s t a t i c   u i n t   L a s t E x p i r a t i o n   =   O R D E R _ T I M E _ G T C ;  
  
         c o n s t   b o o l   S y m b F l a g   =   ( L a s t S y m b   ! =   S y m b ) ;  
  
         i f   ( ( L a s t E x p i r a t i o n   ! =   E x p i r a t i o n )   | |   S y m b F l a g )  
         {  
             L a s t E x p i r a t i o n   =   E x p i r a t i o n ;  
  
             i f   ( S y m b F l a g )  
                 L a s t S y m b   =   S y m b ;  
  
             c o n s t   i n t   E x p i r a t i o n M o d e   =   ( i n t ) : : S y m b o l I n f o I n t e g e r ( S y m b ,   S Y M B O L _ E X P I R A T I O N _ M O D E ) ;  
  
             i f   ( ( E x p i r a t i o n   >   O R D E R _ T I M E _ S P E C I F I E D _ D A Y )   | |   ( ! ( ( E x p i r a t i o n M o d e   > >   E x p i r a t i o n )   &   1 ) ) )  
             {  
                 i f   ( ( E x p i r a t i o n   <   O R D E R _ T I M E _ S P E C I F I E D )   | |   ( E x p i r a t i o n M o d e   <   S Y M B O L _ E X P I R A T I O N _ S P E C I F I E D ) )  
                     E x p i r a t i o n   =   O R D E R _ T I M E _ G T C ;  
                 e l s e   i f   ( E x p i r a t i o n   >   O R D E R _ T I M E _ D A Y )  
                     E x p i r a t i o n   =   O R D E R _ T I M E _ S P E C I F I E D ;  
  
                 u i n t   i   =   1   < <   E x p i r a t i o n ;  
  
                 w h i l e   ( ( E x p i r a t i o n   < =   O R D E R _ T I M E _ S P E C I F I E D _ D A Y )   & &   ( ( E x p i r a t i o n M o d e   &   i )   ! =   i ) )  
                 {  
                     i   < < =   1 ;  
                     E x p i r a t i o n + + ;  
                 }  
             }  
  
             R e s   =   ( E N U M _ O R D E R _ T Y P E _ T I M E ) E x p i r a t i o n ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   M o d i f y O r d e r (   c o n s t   l o n g   & T i c k e t ,   c o n s t   d o u b l e   & P r i c e ,   c o n s t   d a t e t i m e   & E x p i r a t i o n ,   M q l T r a d e R e q u e s t   & R e q u e s t   )  
     {  
         c o n s t   b o o l   R e s   =   : : O r d e r S e l e c t ( T i c k e t ) ;  
  
         i f   ( R e s )  
         {  
             R e q u e s t . a c t i o n   =   T R A D E _ A C T I O N _ M O D I F Y ;  
             R e q u e s t . o r d e r   =   T i c k e t ;  
  
             R e q u e s t . p r i c e   =   P r i c e ;  
  
             R e q u e s t . s y m b o l   =   : : O r d e r G e t S t r i n g ( O R D E R _ S Y M B O L ) ;  
  
             / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 1 1 1 1 / p a g e 1 8 1 7 # c o m m e n t _ 4 0 8 7 2 7 5  
 / /             R e q u e s t . t y p e _ f i l l i n g   =   ( E N U M _ O R D E R _ T Y P E _ F I L L I N G ) : : O r d e r G e t I n t e g e r ( O R D E R _ T Y P E _ F I L L I N G ) ;  
             R e q u e s t . t y p e _ f i l l i n g   =   M T 4 O R D E R S : : G e t F i l l i n g ( R e q u e s t . s y m b o l ) ;  
             R e q u e s t . t y p e _ t i m e   =   M T 4 O R D E R S : : G e t E x p i r a t i o n T y p e ( R e q u e s t . s y m b o l ,   ( u i n t ) E x p i r a t i o n ) ;  
  
             i f   ( E x p i r a t i o n   >   O R D E R _ T I M E _ D A Y )  
                 R e q u e s t . e x p i r a t i o n   =   E x p i r a t i o n ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   S e l e c t B y P o s H i s t o r y (   c o n s t   i n t   I n d e x   )  
     {  
         c o n s t   l o n g   T i c k e t   =   M T 4 O R D E R S : : H i s t o r y [ I n d e x ] ;  
         c o n s t   b o o l   R e s   =   ( T i c k e t   >   0 )   ?   : : H i s t o r y D e a l S e l e c t ( T i c k e t )   :   ( ( T i c k e t   <   0 )   ?   : : H i s t o r y O r d e r S e l e c t ( - T i c k e t )   :   f a l s e ) ;  
  
         i f   ( R e s )  
         {  
             i f   ( T i c k e t   >   0 )  
                 M T 4 O R D E R S : : G e t H i s t o r y P o s i t i o n D a t a ( T i c k e t ) ;  
             e l s e  
                 M T 4 O R D E R S : : G e t H i s t o r y O r d e r D a t a ( - T i c k e t ) ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 2 2 7 9 6 0 # c o m m e n t _ 6 6 0 3 5 0 6  
     s t a t i c   b o o l   O r d e r V i s i b l e (   v o i d   )  
     {  
 / *         c o n s t   E N U M _ O R D E R _ S T A T E   O r d e r S t a t e   =   ( E N U M _ O R D E R _ S T A T E ) : : O r d e r G e t I n t e g e r ( O R D E R _ S T A T E ) ;  
  
         r e t u r n ( ( O r d e r S t a t e   = =   O R D E R _ S T A T E _ P L A C E D )   | |   ( O r d e r S t a t e   = =   O R D E R _ S T A T E _ P A R T I A L ) ) ;  
 * /  
         b o o l   R e s   =   ! : : O r d e r G e t I n t e g e r ( O R D E R _ P O S I T I O N _ I D ) ;  
  
         i f   ( R e s )  
         {  
             c o n s t   l o n g   T i c k e t   =   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I C K E T ) ;  
  
             i f   ( : : P o s i t i o n S e l e c t B y T i c k e t ( : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T ) ) )   / /   O r d e r   a n d   i t s   p o s i t i o n   c a n   b e   s i m u l t a n e o u s   -   t h i s   c o n d i t i o n   w i l l   o n l y   h e l p   o n   H e d g e   a c c o u n t s  
             {  
                 i f   ( T i c k e t   & &   ( : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I C K E T )   ! =   T i c k e t ) )  
                     : : P o s i t i o n S e l e c t B y T i c k e t ( T i c k e t ) ;  
  
                 R e s   =   f a l s e ;  
             }  
         }  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   u l o n g   O r d e r G e t T i c k e t (   c o n s t   i n t   I n d e x   )  
     {  
         u l o n g   R e s ;  
         i n t   P r e v T o t a l ;  
         c o n s t   l o n g   P r e v T i c k e t   =   : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T ) ;  
  
         d o  
         {  
             R e s   =   0 ;  
             P r e v T o t a l   =   : : O r d e r s T o t a l ( ) ;  
  
             i f   ( ( I n d e x   > =   0 )   & &   ( I n d e x   <   P r e v T o t a l ) )  
             {  
                 i n t   C o u n t   =   0 ;  
  
                 f o r   ( i n t   i   =   0 ;   i   <   P r e v T o t a l ;   i + + )  
                 {  
                     c o n s t   i n t   T o t a l   =   : : O r d e r s T o t a l ( ) ;  
  
                     / /   N u m b e r   o f   o r d e r s   m a y   c h a n g e   w h i l e   s e a r c h i n g   f o r  
                     i f   ( T o t a l   ! =   P r e v T o t a l )  
                     {  
                         P r e v T o t a l   =   T o t a l ;  
  
                         C o u n t   =   0 ;  
                         i   =   - 1 ;  
                     }  
                     e l s e  
                     {  
                         c o n s t   u l o n g   T i c k e t   =   : : O r d e r G e t T i c k e t ( i ) ;  
  
                         i f   ( T i c k e t   & &   M T 4 O R D E R S : : O r d e r V i s i b l e ( ) )  
                         {  
                             i f   ( C o u n t   = =   I n d e x )  
                             {  
                                 R e s   =   T i c k e t ;  
  
                                 b r e a k ;  
                             }  
  
                             C o u n t + + ;  
                         }  
                     }  
                 }  
  
                 / /   I n   c a s e   o f   a   f a i l u r e ,   s e l e c t   t h e   o r d e r   t h a t   h a v e   b e e n   c h o s e n   e a r l i e r .  
                 i f   ( ! R e s   & &   P r e v T i c k e t   & &   ( : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T )   ! =   P r e v T i c k e t ) )  
                     c o n s t   b o o l   A n t i W a r n i n g   =   : : O r d e r S e l e c t ( P r e v T i c k e t ) ;  
             }  
         }   w h i l e   ( P r e v T o t a l   ! =   : : O r d e r s T o t a l ( ) ) ;   / /   N u m b e r   o f   o r d e r s   m a y   c h a n g e   w h i l e   s e a r c h i n g   f o r  
  
         r e t u r n ( R e s ) ;  
     }  
  
     / /   W i t h   t h e   s a m e   t i c k e t s ,   t h e   p r i o r i t y   o f   p o s i t i o n   s e l e c t i o n   i s   h i g h e r   t h a n   o r d e r   s e l e c t i o n  
     s t a t i c   b o o l   S e l e c t B y P o s (   c o n s t   i n t   I n d e x   )  
     {  
         c o n s t   i n t   T o t a l   =   : : P o s i t i o n s T o t a l ( ) ;  
         c o n s t   b o o l   F l a g   =   ( I n d e x   <   T o t a l ) ;  
  
         c o n s t   b o o l   R e s   =   ( F l a g )   ?   : : P o s i t i o n G e t T i c k e t ( I n d e x )   :  
                                                                                                                   # i f d e f   M T 4 O R D E R S _ S E L E C T F I L T E R _ O F F  
                                                                                                                       : : O r d e r G e t T i c k e t ( I n d e x   -   T o t a l ) ;  
                                                                                                                   # e l s e   / /   M T 4 O R D E R S _ S E L E C T F I L T E R _ O F F  
                                                                                                                       ( M T 4 O R D E R S : : I s T e s t e r   ?   : : O r d e r G e t T i c k e t ( I n d e x   -   T o t a l )   :   M T 4 O R D E R S : : O r d e r G e t T i c k e t ( I n d e x   -   T o t a l ) ) ;  
                                                                                                                   # e n d i f   / / M T 4 O R D E R S _ S E L E C T F I L T E R _ O F F  
  
         i f   ( R e s )  
         {  
             i f   ( F l a g )  
                 M T 4 O R D E R S : : G e t P o s i t i o n D a t a ( ) ;  
             e l s e  
                 M T 4 O R D E R S : : G e t O r d e r D a t a ( ) ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   S e l e c t B y H i s t o r y T i c k e t (   c o n s t   l o n g   & T i c k e t   )  
     {  
         b o o l   R e s   =   f a l s e ;  
  
         i f   ( : : H i s t o r y D e a l S e l e c t ( T i c k e t ) )  
         {  
             i f   ( M T 4 H I S T O R Y : : I s M T 4 D e a l ( T i c k e t ) )  
             {  
                 M T 4 O R D E R S : : G e t H i s t o r y P o s i t i o n D a t a ( T i c k e t ) ;  
  
                 R e s   =   t r u e ;  
             }  
             e l s e  
             {  
                 c o n s t   u l o n g   T i c k e t D e a l O u t   =   M T 4 O R D E R S : : H i s t o r y . G e t P o s i t i o n D e a l O u t ( H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ P O S I T I O N _ I D ) ) ;   / /   K1>@  ?>  D e a l I n  
  
                 i f   ( : : H i s t o r y D e a l S e l e c t ( T i c k e t D e a l O u t ) )  
                 {  
                     M T 4 O R D E R S : : G e t H i s t o r y P o s i t i o n D a t a ( T i c k e t D e a l O u t ) ;  
  
                     R e s   =   t r u e ;  
                 }  
             }  
         }  
         e l s e   i f   ( : : H i s t o r y O r d e r S e l e c t ( T i c k e t ) )  
         {  
             i f   ( M T 4 H I S T O R Y : : I s M T 4 O r d e r ( T i c k e t ) )  
             {  
                 M T 4 O R D E R S : : G e t H i s t o r y O r d e r D a t a ( T i c k e t ) ;  
  
                 R e s   =   t r u e ;  
             }  
             e l s e  
             {  
                 / /   C h o o s i n g   b y   O r d e r T i c k e t I D   o r   b y   t h e   t i c k e t   o f   a n   e x e c u t e d   p e n d i n g   o r d e r   i s   r e l e v a n t   t o   N e t t i n g .  
                 c o n s t   u l o n g   T i c k e t D e a l O u t   =   M T 4 O R D E R S : : H i s t o r y . G e t P o s i t i o n D e a l O u t ( H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ P O S I T I O N _ I D ) ) ;  
  
                 i f   ( : : H i s t o r y D e a l S e l e c t ( T i c k e t D e a l O u t ) )  
                 {  
                     M T 4 O R D E R S : : G e t H i s t o r y P o s i t i o n D a t a ( T i c k e t D e a l O u t ) ;  
  
                     R e s   =   t r u e ;  
                 }  
             }  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   S e l e c t B y E x i s t i n g T i c k e t (   c o n s t   l o n g   & T i c k e t   )  
     {  
         b o o l   R e s   =   t r u e ;  
  
         i f   ( : : P o s i t i o n S e l e c t B y T i c k e t ( T i c k e t ) )  
             M T 4 O R D E R S : : G e t P o s i t i o n D a t a ( ) ;  
         e l s e   i f   ( : : O r d e r S e l e c t ( T i c k e t ) )  
             M T 4 O R D E R S : : G e t O r d e r D a t a ( ) ;  
         e l s e   i f   ( : : H i s t o r y D e a l S e l e c t ( T i c k e t ) )  
         {  
             i f   ( M T 4 H I S T O R Y : : I s M T 4 D e a l ( T i c k e t ) )   / /   I f   t h   c h o i c e   i s   m a d e   b y   D e a l O u t .  
                 M T 4 O R D E R S : : G e t H i s t o r y P o s i t i o n D a t a ( T i c k e t ) ;  
             e l s e   i f   ( : : P o s i t i o n S e l e c t B y T i c k e t ( : : H i s t o r y D e a l G e t I n t e g e r ( T i c k e t ,   D E A L _ P O S I T I O N _ I D ) ) )   / /   C h o i c e   b y   D e a l I n  
                 M T 4 O R D E R S : : G e t P o s i t i o n D a t a ( ) ;  
             e l s e  
                 R e s   =   f a l s e ;  
         }  
         e l s e   i f   ( : : H i s t o r y O r d e r S e l e c t ( T i c k e t )   & &   : : P o s i t i o n S e l e c t B y T i c k e t ( : : H i s t o r y O r d e r G e t I n t e g e r ( T i c k e t ,   O R D E R _ P O S I T I O N _ I D ) ) )   / /   C h o i c e   b y   t h e   M T 5   o r d e r   t i c k e t  
             M T 4 O R D E R S : : G e t P o s i t i o n D a t a ( ) ;  
         e l s e  
             R e s   =   f a l s e ;  
  
         r e t u r n ( R e s ) ;  
     }  
  
     / /   W i t h   t h e   s a m e   t i c k e t ,   s e l e c t i o n   p r i o r i t i e s   a r e :  
     / /   M O D E _ T R A D E S :     e x i s t i n g   p o s i t i o n   >   e x i s t i n g   o r d e r   >   d e a l   >   c a n c e l e d   o r d e r  
     / /   M O D E _ H I S T O R Y :   d e a l   >   c a n c e l e d   o r d e r   >   e x i s t i n g   p o s i t i o n   >   e x i s t i n g   o r d e r  
     s t a t i c   b o o l   S e l e c t B y T i c k e t (   c o n s t   l o n g   & T i c k e t ,   c o n s t   i n t   & P o o l   )  
     {  
         r e t u r n ( ( P o o l   = =   M O D E _ T R A D E S )   ?  
                       ( M T 4 O R D E R S : : S e l e c t B y E x i s t i n g T i c k e t ( T i c k e t )   ?   t r u e   :   M T 4 O R D E R S : : S e l e c t B y H i s t o r y T i c k e t ( T i c k e t ) )   :  
                       ( M T 4 O R D E R S : : S e l e c t B y H i s t o r y T i c k e t ( T i c k e t )   ?   t r u e   :   M T 4 O R D E R S : : S e l e c t B y E x i s t i n g T i c k e t ( T i c k e t ) ) ) ;  
     }  
  
 # i f d e f   M T 4 O R D E R S _ S L T P _ O L D  
     s t a t i c   v o i d   C h e c k P r i c e s (   d o u b l e   & M i n P r i c e ,   d o u b l e   & M a x P r i c e ,   c o n s t   d o u b l e   M i n ,   c o n s t   d o u b l e   M a x   )  
     {  
         i f   ( M i n P r i c e   & &   ( M i n P r i c e   > =   M i n ) )  
             M i n P r i c e   =   0 ;  
  
         i f   ( M a x P r i c e   & &   ( M a x P r i c e   < =   M a x ) )  
             M a x P r i c e   =   0 ;  
  
         r e t u r n ;  
     }  
 # e n d i f   / /   M T 4 O R D E R S _ S L T P _ O L D  
  
     s t a t i c   i n t   O r d e r s T o t a l (   v o i d   )  
     {  
         i n t   R e s   =   0 ;  
         c o n s t   l o n g   P r e v T i c k e t   =   : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T ) ;  
         i n t   P r e v T o t a l ;  
  
         d o  
         {  
             P r e v T o t a l   =   : : O r d e r s T o t a l ( ) ;  
  
             f o r   ( i n t   i   =   P r e v T o t a l   -   1 ;   i   > =   0 ;   i - - )  
             {  
                 c o n s t   i n t   T o t a l   =   : : O r d e r s T o t a l ( ) ;  
  
                 / /   N u m b e r   o f   o r d e r s   m a y   c h a n g e   w h i l e   s e a r c h i n g   f o r  
                 i f   ( T o t a l   ! =   P r e v T o t a l )  
                 {  
                     P r e v T o t a l   =   T o t a l ;  
  
                     R e s   =   0 ;  
                     i   =   P r e v T o t a l ;  
                 }  
                 e l s e   i f   ( : : O r d e r G e t T i c k e t ( i )   & &   M T 4 O R D E R S : : O r d e r V i s i b l e ( ) )  
                     R e s + + ;  
             }  
         }   w h i l e   ( P r e v T o t a l   ! =   : : O r d e r s T o t a l ( ) ) ;   / /   N u m b e r   o f   o r d e r s   m a y   c h a n g e   w h i l e   s e a r c h i n g   f o r  
  
         i f   ( P r e v T i c k e t   & &   ( : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T )   ! =   P r e v T i c k e t ) )  
             c o n s t   b o o l   A n t i W a r n i n g   =   : : O r d e r S e l e c t ( P r e v T i c k e t ) ;  
  
         r e t u r n ( R e s ) ;  
     }  
  
 p u b l i c :  
     s t a t i c   u i n t   O r d e r S e n d _ M a x P a u s e ;   / /   t h e   m a x i m u m   t i m e   f o r   s y n c h r o n i z a t i o n   i n   m i c r o s e c o n d s .  
  
     s t a t i c   M q l T r a d e R e s u l t   L a s t T r a d e R e s u l t ;  
     s t a t i c   M q l T r a d e R e q u e s t   L a s t T r a d e R e q u e s t ;  
     s t a t i c   M q l T r a d e C h e c k R e s u l t   L a s t T r a d e C h e c k R e s u l t ;  
  
     s t a t i c   b o o l   M T 4 O r d e r S e l e c t (   c o n s t   l o n g   & I n d e x ,   c o n s t   i n t   & S e l e c t ,   c o n s t   i n t   & P o o l   )  
     {  
         r e t u r n ( ( S e l e c t   = =   S E L E C T _ B Y _ P O S )   ?  
                       ( ( P o o l   = =   M O D E _ T R A D E S )   ?   M T 4 O R D E R S : : S e l e c t B y P o s ( ( i n t ) I n d e x )   :   M T 4 O R D E R S : : S e l e c t B y P o s H i s t o r y ( ( i n t ) I n d e x ) )   :  
                       M T 4 O R D E R S : : S e l e c t B y T i c k e t ( I n d e x ,   P o o l ) ) ;  
     }  
  
     / /   T h i s   " o v e r l o a d "   a l l o w s   u s i n g   t h e   M e t a T r a d e r   5   v e r s i o n   o f   O r d e r S e l e c t  
     s t a t i c   b o o l   M T 4 O r d e r S e l e c t (   c o n s t   u l o n g   & T i c k e t   )  
     {  
         r e t u r n ( : : O r d e r S e l e c t ( T i c k e t ) ) ;  
     }  
  
     s t a t i c   i n t   M T 4 O r d e r s T o t a l (   v o i d   )  
     {  
     # i f d e f   M T 4 O R D E R S _ S E L E C T F I L T E R _ O F F  
         r e t u r n ( : : O r d e r s T o t a l ( )   +   +   : : P o s i t i o n s T o t a l ( ) ) ;  
     # e l s e   / /   M T 4 O R D E R S _ S E L E C T F I L T E R _ O F F  
         i n t   R e s ;  
  
         i f   ( M T 4 O R D E R S : : I s T e s t e r )  
             r e t u r n ( : : O r d e r s T o t a l ( )   +   +   : : P o s i t i o n s T o t a l ( ) ) ;  
         e l s e  
         {  
             i n t   P r e v T o t a l ;  
  
             d o  
             {  
                 P r e v T o t a l   =   : : P o s i t i o n s T o t a l ( ) ;  
  
                 R e s   =   M T 4 O R D E R S : : O r d e r s T o t a l ( )   +   P r e v T o t a l ;  
  
             }   w h i l e   ( P r e v T o t a l   ! =   : : P o s i t i o n s T o t a l ( ) ) ;   / /   O n l y   p o s i t i o n   c h a n g e s   a r e   t r a c k e d ,   s i n c e   o r d e r s   a r e   t r a c k e d   i n   M T 4 O R D E R S : : O r d e r s T o t a l ( )  
         }  
  
         r e t u r n ( R e s ) ;   / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 2 9 0 6 7 3 # c o m m e n t _ 9 4 9 3 2 4 1  
     # e n d i f   / / M T 4 O R D E R S _ S E L E C T F I L T E R _ O F F  
     }  
  
     / /   T h i s   " o v e r l o a d "   a l s o   a l l o w s   u s i n g   t h e   M T 5   v e r s i o n   o f   O r d e r s T o t a l  
     s t a t i c   i n t   M T 4 O r d e r s T o t a l (   c o n s t   b o o l   )  
     {  
         r e t u r n ( : : O r d e r s T o t a l ( ) ) ;  
     }  
  
     s t a t i c   i n t   M T 4 O r d e r s H i s t o r y T o t a l (   v o i d   )  
     {  
         r e t u r n ( M T 4 O R D E R S : : H i s t o r y . G e t A m o u n t ( ) ) ;  
     }  
  
     s t a t i c   l o n g   M T 4 O r d e r S e n d (   c o n s t   s t r i n g   & S y m b ,   c o n s t   i n t   & T y p e ,   c o n s t   d o u b l e   & d V o l u m e ,   c o n s t   d o u b l e   & P r i c e ,   c o n s t   i n t   & S l i p P a g e ,   c o n s t   d o u b l e   & S L ,   c o n s t   d o u b l e   & T P ,  
                                                         c o n s t   s t r i n g   & c o m m e n t ,   c o n s t   M A G I C _ T Y P E   & m a g i c ,   c o n s t   d a t e t i m e   & d E x p i r a t i o n ,   c o n s t   c o l o r   & a r r o w _ c o l o r   )  
  
     {  
         : : Z e r o M e m o r y ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ) ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . a c t i o n   =   ( ( ( T y p e   = =   O P _ B U Y )   | |   ( T y p e   = =   O P _ S E L L ) )   ?   T R A D E _ A C T I O N _ D E A L   :   T R A D E _ A C T I O N _ P E N D I N G ) ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . m a g i c   =   m a g i c ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l   =   ( ( S y m b   = =   N U L L )   ?   : : S y m b o l ( )   :   S y m b ) ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . v o l u m e   =   d V o l u m e ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . p r i c e   =   P r i c e ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t p   =   T P ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s l   =   S L ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . d e v i a t i o n   =   S l i p P a g e ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t y p e   =   ( E N U M _ O R D E R _ T Y P E ) T y p e ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t y p e _ f i l l i n g   =   M T 4 O R D E R S : : G e t F i l l i n g ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l ,   ( u i n t ) M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . d e v i a t i o n ) ;  
  
         i f   ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . a c t i o n   = =   T R A D E _ A C T I O N _ P E N D I N G )  
         {  
             M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t y p e _ t i m e   =   M T 4 O R D E R S : : G e t E x p i r a t i o n T y p e ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l ,   ( u i n t ) d E x p i r a t i o n ) ;  
  
             i f   ( d E x p i r a t i o n   >   O R D E R _ T I M E _ D A Y )  
                 M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . e x p i r a t i o n   =   d E x p i r a t i o n ;  
         }  
  
         i f   ( c o m m e n t   ! =   N U L L )  
             M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . c o m m e n t   =   c o m m e n t ;  
  
         r e t u r n ( ( a r r o w _ c o l o r   = =   I N T _ M A X )   ?   ( M T 4 O R D E R S : : N e w O r d e r C h e c k ( )   ?   0   :   - 1 )   :  
                       ( ( ( ( i n t ) a r r o w _ c o l o r   ! =   I N T _ M I N )   | |   M T 4 O R D E R S : : N e w O r d e r C h e c k ( ) )   & &  
                         M T 4 O R D E R S : : O r d e r S e n d ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ,   M T 4 O R D E R S : : L a s t T r a d e R e s u l t )   ?  
                         ( M T 4 O R D E R S : : I s H e d g i n g   ?   ( l o n g ) M T 4 O R D E R S : : L a s t T r a d e R e s u l t . o r d e r   :   / /   P o s i t i o n I D   = =   R e s u l t . o r d e r   -   a   f e a t u r e   o f   M T 5 - H e d g e  
                           ( ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . a c t i o n   = =   T R A D E _ A C T I O N _ D E A L )   ?  
                             ( M T 4 O R D E R S : : I s T e s t e r   ?   ( : : P o s i t i o n S e l e c t ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l )   ?   P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I C K E T )   :   0 )   :  
                                                                             / /   H i s t o r y D e a l S e l e c t   2  M T 4 O R D E R S : : O r d e r S e n d  
                                                                             : : H i s t o r y D e a l G e t I n t e g e r ( M T 4 O R D E R S : : L a s t T r a d e R e s u l t . d e a l ,   D E A L _ P O S I T I O N _ I D ) )   :  
                             ( l o n g ) M T 4 O R D E R S : : L a s t T r a d e R e s u l t . o r d e r ) )   :   - 1 ) ) ;  
     }  
  
     s t a t i c   b o o l   M T 4 O r d e r M o d i f y (   c o n s t   l o n g   & T i c k e t ,   c o n s t   d o u b l e   & P r i c e ,   c o n s t   d o u b l e   & S L ,   c o n s t   d o u b l e   & T P ,   c o n s t   d a t e t i m e   & E x p i r a t i o n ,   c o n s t   c o l o r   & A r r o w _ C o l o r   )  
     {  
         : : Z e r o M e m o r y ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ) ;  
  
                               / /   C o n s i d e r s   t h e   c a s e   w h e n   a n   o r d e r   a n d   a   p o s i t i o n   w i t h   t h e   s a m e   t i c k e t   a r e   p r e s e n t  
         b o o l   R e s   =   ( ( T i c k e t   ! =   M T 4 O R D E R S : : O r d e r . T i c k e t )   | |   ( M T 4 O R D E R S : : O r d e r . T i c k e t   < =   O P _ S E L L ) )   ?  
                               ( M T 4 O R D E R S : : M o d i f y P o s i t i o n ( T i c k e t ,   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t )   ?   t r u e   :   M T 4 O R D E R S : : M o d i f y O r d e r ( T i c k e t ,   P r i c e ,   E x p i r a t i o n ,   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ) )   :  
                               ( M T 4 O R D E R S : : M o d i f y O r d e r ( T i c k e t ,   P r i c e ,   E x p i r a t i o n ,   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t )   ?   t r u e   :   M T 4 O R D E R S : : M o d i f y P o s i t i o n ( T i c k e t ,   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ) ) ;  
  
 / /         i f   ( R e s )   / /   I g n o r e   t h e   c h e c k   -   O r d e r C h e c k   i s   p r e s e n t  
         {  
             M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t p   =   T P ;  
             M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s l   =   S L ;  
  
             R e s   =   M T 4 O R D E R S : : N e w O r d e r S e n d ( A r r o w _ C o l o r ) ;  
         }  
  
         r e t u r n ( R e s ) ;  
     }  
  
     s t a t i c   b o o l   M T 4 O r d e r C l o s e (   c o n s t   l o n g   & T i c k e t ,   c o n s t   d o u b l e   & d L o t s ,   c o n s t   d o u b l e   & P r i c e ,   c o n s t   i n t   & S l i p P a g e ,   c o n s t   c o l o r   & A r r o w _ C o l o r ,   c o n s t   s t r i n g   & c o m m e n t   )  
     {  
         / /   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t   a n d   M T 4 O R D E R S : : L a s t T r a d e R e s u l t   a r e   p r e s e n t ,   t h e r e f o r e   t h e   r e s u l t   i s   n o t   a f f e c t e d .   H o w e v e r ,   i t   i s   n e c e s s a r y   f o r   P o s i t i o n G e t S t r i n g   b e l o w  
         : : P o s i t i o n S e l e c t B y T i c k e t ( T i c k e t ) ;  
  
         : : Z e r o M e m o r y ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ) ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . a c t i o n   =   T R A D E _ A C T I O N _ D E A L ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . p o s i t i o n   =   T i c k e t ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l   =   : : P o s i t i o n G e t S t r i n g ( P O S I T I O N _ S Y M B O L ) ;  
  
         / /   S a v e   t h e   c o m m e n t   w h e n   p a r t i a l l y   c l o s i n g   t h e   p o s i t i o n  
 / /         i f   ( d L o t s   <   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ V O L U M E ) )  
             M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . c o m m e n t   =   ( c o m m e n t   = =   N U L L )   ?   : : P o s i t i o n G e t S t r i n g ( P O S I T I O N _ C O M M E N T )   :   c o m m e n t ;  
  
         / /   I s   i t   c o r r e c t   n o t   t o   d e f i n e   m a g i c   n u m b e r   w h e n   c l o s i n g ?   - I t   i s !  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . v o l u m e   =   d L o t s ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . p r i c e   =   P r i c e ;  
  
     # i f d e f   M T 4 O R D E R S _ S L T P _ O L D  
         / /   N e e d e d   t o   d e t e r m i n e   t h e   S L / T P   l e v e l s   o f   t h e   c l o s e d   p o s i t i o n .   I n v e r t e d   -   n o t   a n   e r r o r  
         / /   S Y M B O L _ S E S S I O N _ P R I C E _ L I M I T _ M I N   a n d   S Y M B O L _ S E S S I O N _ P R I C E _ L I M I T _ M A X   d o   n o t   n e e d   a n y   v a l i d a t i o n ,   s i n c e   t h e   i n i t i a l   S L / T P   h a v e   a l r e a d y   b e e n   s e t  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t p   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ S L ) ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s l   =   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ T P ) ;  
  
         i f   ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t p   | |   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s l )  
         {  
             c o n s t   d o u b l e   S t o p L e v e l   =   : : S y m b o l I n f o I n t e g e r ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l ,   S Y M B O L _ T R A D E _ S T O P S _ L E V E L )   *  
                                                               : : S y m b o l I n f o D o u b l e ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l ,   S Y M B O L _ P O I N T ) ;  
  
             c o n s t   b o o l   F l a g B u y   =   ( : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T Y P E )   = =   P O S I T I O N _ T Y P E _ B U Y ) ;  
             c o n s t   d o u b l e   C u r r e n t P r i c e   =   S y m b o l I n f o D o u b l e ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l ,   F l a g B u y   ?   S Y M B O L _ A S K   :   S Y M B O L _ B I D ) ;  
  
             i f   ( C u r r e n t P r i c e )  
             {  
                 i f   ( F l a g B u y )  
                     M T 4 O R D E R S : : C h e c k P r i c e s ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t p ,   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s l ,   C u r r e n t P r i c e   -   S t o p L e v e l ,   C u r r e n t P r i c e   +   S t o p L e v e l ) ;  
                 e l s e  
                     M T 4 O R D E R S : : C h e c k P r i c e s ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s l ,   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t p ,   C u r r e n t P r i c e   -   S t o p L e v e l ,   C u r r e n t P r i c e   +   S t o p L e v e l ) ;  
             }  
             e l s e  
             {  
                 M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t p   =   0 ;  
                 M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s l   =   0 ;  
             }  
         }  
     # e n d i f   / /   M T 4 O R D E R S _ S L T P _ O L D  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . d e v i a t i o n   =   S l i p P a g e ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t y p e   =   ( E N U M _ O R D E R _ T Y P E ) ( 1   -   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T Y P E ) ) ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . t y p e _ f i l l i n g   =   M T 4 O R D E R S : : G e t F i l l i n g ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l ,   ( u i n t ) M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . d e v i a t i o n ) ;  
  
         r e t u r n ( M T 4 O R D E R S : : N e w O r d e r S e n d ( A r r o w _ C o l o r ) ) ;  
     }  
  
     s t a t i c   b o o l   M T 4 O r d e r C l o s e B y (   c o n s t   l o n g   & T i c k e t ,   c o n s t   l o n g   & O p p o s i t e ,   c o n s t   c o l o r   & A r r o w _ C o l o r   )  
     {  
         : : Z e r o M e m o r y ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ) ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . a c t i o n   =   T R A D E _ A C T I O N _ C L O S E _ B Y ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . p o s i t i o n   =   T i c k e t ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . p o s i t i o n _ b y   =   O p p o s i t e ;  
  
         i f   ( ( ! M T 4 O R D E R S : : I s T e s t e r )   & &   : : P o s i t i o n S e l e c t B y T i c k e t ( T i c k e t ) )   / /   n e e d e   f o r   M T 4 O R D E R S : : S y m b o l T r a d e ( )  
             M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l   =   : : P o s i t i o n G e t S t r i n g ( P O S I T I O N _ S Y M B O L ) ;  
  
         r e t u r n ( M T 4 O R D E R S : : N e w O r d e r S e n d ( A r r o w _ C o l o r ) ) ;  
     }  
  
     s t a t i c   b o o l   M T 4 O r d e r D e l e t e (   c o n s t   l o n g   & T i c k e t ,   c o n s t   c o l o r   & A r r o w _ C o l o r   )  
     {  
 / /         b o o l   R e s   =   : : O r d e r S e l e c t ( T i c k e t ) ;   / /   I s   i t   n e c e s s a r y ,   w h e n   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t   a n d   M T 4 O R D E R S : : L a s t T r a d e R e s u l t   a r e   n e e d e d ?  
  
         : : Z e r o M e m o r y ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ) ;  
  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . a c t i o n   =   T R A D E _ A C T I O N _ R E M O V E ;  
         M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . o r d e r   =   T i c k e t ;  
  
         i f   ( ( ! M T 4 O R D E R S : : I s T e s t e r )   & &   : : O r d e r S e l e c t ( T i c k e t ) )   / /   n e c e s s a r y   f o r   M T 4 O R D E R S : : S y m b o l T r a d e ( )  
             M T 4 O R D E R S : : L a s t T r a d e R e q u e s t . s y m b o l   =   : : O r d e r G e t S t r i n g ( O R D E R _ S Y M B O L ) ;  
  
         r e t u r n ( M T 4 O R D E R S : : N e w O r d e r S e n d ( A r r o w _ C o l o r ) ) ;  
     }  
  
 # d e f i n e   M T 4 _ O R D E R F U N C T I O N ( N A M E , T , A , B , C )                                                               \  
     s t a t i c   T   M T 4 O r d e r # # N A M E (   v o i d   )                                                                           \  
     {                                                                                                                                       \  
         r e t u r n ( P O S I T I O N _ O R D E R ( ( T ) ( A ) ,   ( T ) ( B ) ,   M T 4 O R D E R S : : O r d e r . N A M E ,   C ) ) ;   \  
     }  
  
 # d e f i n e   P O S I T I O N _ O R D E R ( A , B , C , D )   ( ( ( M T 4 O R D E R S : : O r d e r . T i c k e t   = =   P O S I T I O N _ S E L E C T )   & &   ( D ) )   ?   ( A )   :   ( ( M T 4 O R D E R S : : O r d e r . T i c k e t   = =   O R D E R _ S E L E C T )   ?   ( B )   :   ( C ) ) )  
  
     M T 4 _ O R D E R F U N C T I O N ( T i c k e t ,   l o n g ,   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I C K E T ) ,   : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( T y p e ,   i n t ,   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T Y P E ) ,   : : O r d e r G e t I n t e g e r ( O R D E R _ T Y P E ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( L o t s ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ V O L U M E ) ,   : : O r d e r G e t D o u b l e ( O R D E R _ V O L U M E _ C U R R E N T ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( O p e n P r i c e ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R I C E _ O P E N ) ,   ( : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ O P E N )   ?   : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ O P E N )   :   : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ C U R R E N T ) ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( O p e n T i m e M s c ,   l o n g ,   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I M E _ M S C ) ,   : : O r d e r G e t I n t e g e r ( O R D E R _ T I M E _ S E T U P _ M S C ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( O p e n T i m e ,   d a t e t i m e ,   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ T I M E ) ,   : : O r d e r G e t I n t e g e r ( O R D E R _ T I M E _ S E T U P ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( S t o p L o s s ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ S L ) ,   : : O r d e r G e t D o u b l e ( O R D E R _ S L ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( T a k e P r o f i t ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ T P ) ,   : : O r d e r G e t D o u b l e ( O R D E R _ T P ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( C l o s e P r i c e ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R I C E _ C U R R E N T ) ,   : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ C U R R E N T ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( C l o s e T i m e M s c ,   l o n g ,   0 ,   0 ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( C l o s e T i m e ,   d a t e t i m e ,   0 ,   0 ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( E x p i r a t i o n ,   d a t e t i m e ,   0 ,   : : O r d e r G e t I n t e g e r ( O R D E R _ T I M E _ E X P I R A T I O N ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( M a g i c N u m b e r ,   l o n g ,   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ M A G I C ) ,   : : O r d e r G e t I n t e g e r ( O R D E R _ M A G I C ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( P r o f i t ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R O F I T ) ,   0 ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( S w a p ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ S W A P ) ,   0 ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( S y m b o l ,   s t r i n g ,   : : P o s i t i o n G e t S t r i n g ( P O S I T I O N _ S Y M B O L ) ,   : : O r d e r G e t S t r i n g ( O R D E R _ S Y M B O L ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( C o m m e n t ,   s t r i n g ,   M T 4 O R D E R S : : O r d e r . C o m m e n t ,   : : O r d e r G e t S t r i n g ( O R D E R _ C O M M E N T ) ,   M T 4 O R D E R S : : C h e c k P o s i t i o n C o m m i s s i o n C o m m e n t ( ) )  
     M T 4 _ O R D E R F U N C T I O N ( C o m m i s s i o n ,   d o u b l e ,   M T 4 O R D E R S : : O r d e r . C o m m i s s i o n ,   0 ,   M T 4 O R D E R S : : C h e c k P o s i t i o n C o m m i s s i o n C o m m e n t ( ) )  
  
     M T 4 _ O R D E R F U N C T I O N ( O p e n P r i c e R e q u e s t ,   d o u b l e ,   M T 4 O R D E R S : : O r d e r . O p e n P r i c e R e q u e s t ,   : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ O P E N ) ,   M T 4 O R D E R S : : C h e c k P o s i t i o n O p e n P r i c e R e q u e s t ( ) )  
     M T 4 _ O R D E R F U N C T I O N ( C l o s e P r i c e R e q u e s t ,   d o u b l e ,   : : P o s i t i o n G e t D o u b l e ( P O S I T I O N _ P R I C E _ C U R R E N T ) ,   : : O r d e r G e t D o u b l e ( O R D E R _ P R I C E _ C U R R E N T ) ,   t r u e )  
  
     M T 4 _ O R D E R F U N C T I O N ( T i c k e t O p e n ,   l o n g ,   M T 4 O R D E R S : : O r d e r . T i c k e t O p e n ,   : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T ) ,   M T 4 O R D E R S : : C h e c k P o s i t i o n T i c k e t O p e n ( ) )  
 / /     M T 4 _ O R D E R F U N C T I O N ( O p e n R e a s o n ,   E N U M _ D E A L _ R E A S O N ,   M T 4 O R D E R S : : O r d e r . O p e n R e a s o n ,   : : O r d e r G e t I n t e g e r ( O R D E R _ R E A S O N ) ,   M T 4 O R D E R S : : C h e c k P o s i t i o n O p e n R e a s o n ( ) )  
     M T 4 _ O R D E R F U N C T I O N ( O p e n R e a s o n ,   E N U M _ D E A L _ R E A S O N ,   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ R E A S O N ) ,   : : O r d e r G e t I n t e g e r ( O R D E R _ R E A S O N ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( C l o s e R e a s o n ,   E N U M _ D E A L _ R E A S O N ,   0 ,   : : O r d e r G e t I n t e g e r ( O R D E R _ R E A S O N ) ,   t r u e )  
     M T 4 _ O R D E R F U N C T I O N ( T i c k e t I D ,   l o n g ,   : : P o s i t i o n G e t I n t e g e r ( P O S I T I O N _ I D E N T I F I E R ) ,   : : O r d e r G e t I n t e g e r ( O R D E R _ T I C K E T ) ,   t r u e )  
  
 # u n d e f   P O S I T I O N _ O R D E R  
 # u n d e f   M T 4 _ O R D E R F U N C T I O N  
  
     s t a t i c   v o i d   M T 4 O r d e r P r i n t (   v o i d   )  
     {  
         i f   ( M T 4 O R D E R S : : O r d e r . T i c k e t   = =   P O S I T I O N _ S E L E C T )  
             M T 4 O R D E R S : : C h e c k P o s i t i o n C o m m i s s i o n C o m m e n t ( ) ;  
  
         : : P r i n t ( M T 4 O R D E R S : : O r d e r . T o S t r i n g ( ) ) ;  
  
         r e t u r n ;  
     }  
  
 # u n d e f   O R D E R _ S E L E C T  
 # u n d e f   P O S I T I O N _ S E L E C T  
 } ;  
  
 / /   # d e f i n e   O r d e r T o S t r i n g   M T 4 O R D E R S : : M T 4 O r d e r T o S t r i n g  
  
 s t a t i c   M T 4 _ O R D E R   M T 4 O R D E R S : : O r d e r   =   { 0 } ;  
  
 s t a t i c   M T 4 H I S T O R Y   M T 4 O R D E R S : : H i s t o r y ;  
  
 s t a t i c   c o n s t   b o o l   M T 4 O R D E R S : : I s T e s t e r   =   : : M Q L I n f o I n t e g e r ( M Q L _ T E S T E R ) ;  
  
 / /   I f   y o u   s w i t c h   t h e   a c c o u n t ,   t h i s   v a l u e   w i l l   s t i l l   b e   r e c a l c u l a t e d   f o r   E A s  
 / /   h t t p s : / / w w w . m q l 5 . c o m / r u / f o r u m / 1 7 0 9 5 2 / p a g e 6 1 # c o m m e n t _ 6 1 3 2 8 2 4  
 s t a t i c   c o n s t   b o o l   M T 4 O R D E R S : : I s H e d g i n g   =   ( ( E N U M _ A C C O U N T _ M A R G I N _ M O D E ) : : A c c o u n t I n f o I n t e g e r ( A C C O U N T _ M A R G I N _ M O D E )   = =  
                                                                                     A C C O U N T _ M A R G I N _ M O D E _ R E T A I L _ H E D G I N G ) ;  
  
 s t a t i c   i n t   M T 4 O R D E R S : : O r d e r S e n d B u g   =   0 ;  
  
 s t a t i c   u i n t   M T 4 O R D E R S : : O r d e r S e n d _ M a x P a u s e   =   1 0 0 0 0 0 0 ;   / /   t h e   m a x i m u m   t i m e   f o r   s y n c h r o n i z a t i o n   i n   m i c r o s e c o n d s .  
  
 s t a t i c   M q l T r a d e R e s u l t   M T 4 O R D E R S : : L a s t T r a d e R e s u l t   =   { 0 } ;  
 s t a t i c   M q l T r a d e R e q u e s t   M T 4 O R D E R S : : L a s t T r a d e R e q u e s t   =   { 0 } ;  
 s t a t i c   M q l T r a d e C h e c k R e s u l t   M T 4 O R D E R S : : L a s t T r a d e C h e c k R e s u l t   =   { 0 } ;  
  
 b o o l   O r d e r C l o s e (   c o n s t   l o n g   T i c k e t ,   c o n s t   d o u b l e   d L o t s ,   c o n s t   d o u b l e   P r i c e ,   c o n s t   i n t   S l i p P a g e ,   c o n s t   c o l o r   A r r o w _ C o l o r   =   c l r N O N E ,   c o n s t   s t r i n g   c o m m e n t   =   N U L L   )  
 {  
     r e t u r n ( M T 4 O R D E R S : : M T 4 O r d e r C l o s e ( T i c k e t ,   d L o t s ,   P r i c e ,   S l i p P a g e ,   A r r o w _ C o l o r ,   c o m m e n t ) ) ;  
 }  
  
 b o o l   O r d e r M o d i f y (   c o n s t   l o n g   T i c k e t ,   c o n s t   d o u b l e   P r i c e ,   c o n s t   d o u b l e   S L ,   c o n s t   d o u b l e   T P ,   c o n s t   d a t e t i m e   E x p i r a t i o n ,   c o n s t   c o l o r   A r r o w _ C o l o r   =   c l r N O N E   )  
 {  
     r e t u r n ( M T 4 O R D E R S : : M T 4 O r d e r M o d i f y ( T i c k e t ,   P r i c e ,   S L ,   T P ,   E x p i r a t i o n ,   A r r o w _ C o l o r ) ) ;  
 }  
  
 b o o l   O r d e r C l o s e B y (   c o n s t   l o n g   T i c k e t ,   c o n s t   l o n g   O p p o s i t e ,   c o n s t   c o l o r   A r r o w _ C o l o r   =   c l r N O N E   )  
 {  
     r e t u r n ( M T 4 O R D E R S : : M T 4 O r d e r C l o s e B y ( T i c k e t ,   O p p o s i t e ,   A r r o w _ C o l o r ) ) ;  
 }  
  
 b o o l   O r d e r D e l e t e (   c o n s t   l o n g   T i c k e t ,   c o n s t   c o l o r   A r r o w _ C o l o r   =   c l r N O N E   )  
 {  
     r e t u r n ( M T 4 O R D E R S : : M T 4 O r d e r D e l e t e ( T i c k e t ,   A r r o w _ C o l o r ) ) ;  
 }  
  
 v o i d   O r d e r P r i n t (   v o i d   )  
 {  
     M T 4 O R D E R S : : M T 4 O r d e r P r i n t ( ) ;  
  
     r e t u r n ;  
 }  
  
 # d e f i n e   M T 4 _ O R D E R G L O B A L F U N C T I O N ( N A M E , T )           \  
     T   O r d e r # # N A M E (   v o i d   )                                           \  
     {                                                                                   \  
         r e t u r n ( ( T ) M T 4 O R D E R S : : M T 4 O r d e r # # N A M E ( ) ) ;   \  
     }  
  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( s H i s t o r y T o t a l ,   i n t )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( T i c k e t ,   T I C K E T _ T Y P E )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( T y p e ,   i n t )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( L o t s ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( O p e n P r i c e ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( O p e n T i m e M s c ,   l o n g )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( O p e n T i m e ,   d a t e t i m e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( S t o p L o s s ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( T a k e P r o f i t ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( C l o s e P r i c e ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( C l o s e T i m e M s c ,   l o n g )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( C l o s e T i m e ,   d a t e t i m e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( E x p i r a t i o n ,   d a t e t i m e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( M a g i c N u m b e r ,   M A G I C _ T Y P E )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( P r o f i t ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( C o m m i s s i o n ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( S w a p ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( S y m b o l ,   s t r i n g )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( C o m m e n t ,   s t r i n g )  
  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( O p e n P r i c e R e q u e s t ,   d o u b l e )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( C l o s e P r i c e R e q u e s t ,   d o u b l e )  
  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( T i c k e t O p e n ,   l o n g )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( O p e n R e a s o n ,   E N U M _ D E A L _ R E A S O N )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( C l o s e R e a s o n ,   E N U M _ D E A L _ R E A S O N )  
 M T 4 _ O R D E R G L O B A L F U N C T I O N ( T i c k e t I D ,   l o n g )  
  
 # u n d e f   M T 4 _ O R D E R G L O B A L F U N C T I O N  
  
 / /   O v e r l o a d e d   s t a n d a r d   f u n c t i o n s  
 # d e f i n e   O r d e r s T o t a l   M T 4 O R D E R S : : M T 4 O r d e r s T o t a l   / /   A F T E R   E x p e r t / E x p e r t . m q h   -   t h e r e   i s   a   c a l l   t o   M T 5 - O r d e r s T o t a l ( )  
  
 b o o l   O r d e r S e l e c t (   c o n s t   l o n g   I n d e x ,   c o n s t   i n t   S e l e c t ,   c o n s t   i n t   P o o l   =   M O D E _ T R A D E S   )  
 {  
     r e t u r n ( M T 4 O R D E R S : : M T 4 O r d e r S e l e c t ( I n d e x ,   S e l e c t ,   P o o l ) ) ;  
 }  
  
 T I C K E T _ T Y P E   O r d e r S e n d (   c o n s t   s t r i n g   S y m b ,   c o n s t   i n t   T y p e ,   c o n s t   d o u b l e   d V o l u m e ,   c o n s t   d o u b l e   P r i c e ,   c o n s t   i n t   S l i p P a g e ,   c o n s t   d o u b l e   S L ,   c o n s t   d o u b l e   T P ,  
                                               c o n s t   s t r i n g   c o m m e n t   =   N U L L ,   c o n s t   M A G I C _ T Y P E   m a g i c   =   0 ,   c o n s t   d a t e t i m e   d E x p i r a t i o n   =   0 ,   c o l o r   a r r o w _ c o l o r   =   c l r N O N E   )  
 {  
     r e t u r n ( ( T I C K E T _ T Y P E ) M T 4 O R D E R S : : M T 4 O r d e r S e n d ( S y m b ,   T y p e ,   d V o l u m e ,   P r i c e ,   S l i p P a g e ,   S L ,   T P ,   c o m m e n t ,   m a g i c ,   d E x p i r a t i o n ,   a r r o w _ c o l o r ) ) ;  
 }  
  
 # d e f i n e   R E T U R N _ A S Y N C ( A )   r e t u r n ( ( A )   & &   : : O r d e r S e n d A s y n c ( M T 4 O R D E R S : : L a s t T r a d e R e q u e s t ,   M T 4 O R D E R S : : L a s t T r a d e R e s u l t )   & &                                                 \  
                                                               ( M T 4 O R D E R S : : L a s t T r a d e R e s u l t . r e t c o d e   = =   T R A D E _ R E T C O D E _ P L A C E D )   ?   M T 4 O R D E R S : : L a s t T r a d e R e s u l t . r e q u e s t _ i d   :   0 ) ;  
  
 u i n t   O r d e r C l o s e A s y n c (   c o n s t   l o n g   T i c k e t ,   c o n s t   d o u b l e   d L o t s ,   c o n s t   d o u b l e   P r i c e ,   c o n s t   i n t   S l i p P a g e ,   c o n s t   c o l o r   A r r o w _ C o l o r   =   c l r N O N E   )  
 {  
     R E T U R N _ A S Y N C ( O r d e r C l o s e ( T i c k e t ,   d L o t s ,   P r i c e ,   S l i p P a g e ,   I N T _ M A X ) )  
 }  
  
 u i n t   O r d e r M o d i f y A s y n c (   c o n s t   l o n g   T i c k e t ,   c o n s t   d o u b l e   P r i c e ,   c o n s t   d o u b l e   S L ,   c o n s t   d o u b l e   T P ,   c o n s t   d a t e t i m e   E x p i r a t i o n ,   c o n s t   c o l o r   A r r o w _ C o l o r   =   c l r N O N E   )  
 {  
     R E T U R N _ A S Y N C ( O r d e r M o d i f y ( T i c k e t ,   P r i c e ,   S L ,   T P ,   E x p i r a t i o n ,   I N T _ M A X ) )  
 }  
  
 u i n t   O r d e r D e l e t e A s y n c (   c o n s t   l o n g   T i c k e t ,   c o n s t   c o l o r   A r r o w _ C o l o r   =   c l r N O N E   )  
 {  
     R E T U R N _ A S Y N C ( O r d e r D e l e t e ( T i c k e t ,   I N T _ M A X ) )  
 }  
  
 u i n t   O r d e r S e n d A s y n c (   c o n s t   s t r i n g   S y m b ,   c o n s t   i n t   T y p e ,   c o n s t   d o u b l e   d V o l u m e ,   c o n s t   d o u b l e   P r i c e ,   c o n s t   i n t   S l i p P a g e ,   c o n s t   d o u b l e   S L ,   c o n s t   d o u b l e   T P ,  
                                         c o n s t   s t r i n g   c o m m e n t   =   N U L L ,   c o n s t   M A G I C _ T Y P E   m a g i c   =   0 ,   c o n s t   d a t e t i m e   d E x p i r a t i o n   =   0 ,   c o l o r   a r r o w _ c o l o r   =   c l r N O N E   )  
 {  
     R E T U R N _ A S Y N C ( ! O r d e r S e n d ( S y m b ,   T y p e ,   d V o l u m e ,   P r i c e ,   S l i p P a g e ,   S L ,   T P ,   c o m m e n t ,   m a g i c ,   d E x p i r a t i o n ,   I N T _ M A X ) )  
 }  
  
 # u n d e f   R E T U R N _ A S Y N C  
  
 # u n d e f   M T 4 O R D E R S _ S L T P _ O L D  
  
 / /   # u n d e f   T I C K E T _ T Y P E  
 # e n d i f   / /   _ _ M T 4 O R D E R S _ _  
 # e l s e     / /   _ _ M Q L 5 _ _  
     # d e f i n e   T I C K E T _ T Y P E   i n t  
     # d e f i n e   M A G I C _ T Y P E     i n t  
 # e n d i f   / /   _ _ M Q L 5 _ _ 