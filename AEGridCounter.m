//
//  AEGridCounter.m
//  NewImageGridView
//
//  Created by АЛЕКСАНДР on 14.01.14.
//  Copyright (c) 2014 АЛЕКСАНДР. All rights reserved.
//

#import "AEGridCounter.h"

//Создадим обьект для хранения переменных

@interface AEImageObject : NSObject
@property (nonatomic, assign) AEImageSizeObject *size;
@property (nonatomic, assign) ShapeType type;
@property (nonatomic, assign) CGRect frame; //Рамка вида { x, y, w, h}
@end

@implementation AEImageObject
@end

@implementation AEImageSizeObject
@end

@implementation AEResultObject
@end

@implementation AEGridCounter

//Singleton
static AEGridCounter *instance = nil;
+ (AEGridCounter *)shared {
    @synchronized (self) {
		if (instance == nil){
            instance = [[self alloc] init];
        }
	}
	return instance;
}





//Здесь рассположены методы которые доступны из других классов (пользовательские методы)
#pragma mark - action methods

/*
  Расчет начинается с размеров изображение, нет смысла хранить в памяти изображение так как нам нужны только его два параметра - длина и ширина!
  Для того чтобы хранить эти два параметра бал создан объект AEImageSizeObject, он так же доступен из других классов для того чтобы пользователь
  мог передать размеры напрямую. После поучения размеров формируется объект AEImageObject, который содержит все параметры для расчета.
*/


//Данный метод принимает на вход массив изображений и параметры блока
-(AEResultObject*)countGrid:(NSMutableArray*)images blockWidth:(int)blockW offset:(int)offset {
    
    NSMutableArray *sizesArray = [[NSMutableArray alloc]init];
    
    //На данном этапе мы должны получить из изображений (bitmap) только размеры
    for (int i=0; i<images.count; i++) {
        UIImage *image = [images objectAtIndex:i];
        
        AEImageSizeObject *imageSizeObject = [[AEImageSizeObject alloc]init];
        imageSizeObject.width = image.size.width;
        imageSizeObject.height = image.size.height;
        [sizesArray addObject:imageSizeObject];
    }
    
    return [self countGridWithSizes:sizesArray blockWidth:blockW offset:offset];
}

//Данный метод принимает на вход массив объектов AEImageSizeObject и параметры блока
-(AEResultObject*)countGridWithSizes:(NSMutableArray *)imageSizes blockWidth:(int)blockW offset:(int)offset {
    blockFrame = CGRectZero;
    offsetP = offset;
    blockWidth = blockW;
    maxHeight = [UIScreen mainScreen].bounds.size.height-200;
    
    NSMutableArray *imageObjects = [[NSMutableArray alloc]init];
    imageObjects = [self getImageObjectsFromSizesArray:imageSizes];
    
    NSMutableArray *frames = [self countGridWithImageObjects:imageObjects];
    
    AEResultObject *result = [[AEResultObject alloc]init];
    result.FramesArray = frames;
    result.blockFrame = blockFrame;
    
    return result;
}





//В этой части рассположены методы которые служат исключительно для расчета и не могут быть использованны пользователем.
#pragma mark - count part

//Здесь мы производем форматирование и создаем объекты типа AEImageObject
-(NSMutableArray*)getImageObjectsFromSizesArray:(NSMutableArray*)imageSizes {
    NSMutableArray *imageObjects = [[NSMutableArray alloc]init];
    for (int i=0; i<imageSizes.count; i++) {
        AEImageSizeObject *imageSize = [imageSizes objectAtIndex:i];
        
        AEImageObject *imageObject = [[AEImageObject alloc]init];
        imageObject.size = imageSize;
        imageObject.type = [self getShapeType:imageSize];
        [imageObjects addObject:imageObject];
    }
    return imageObjects;
}

//Данный метод начинает расчет и принимает на вход массив объектов типа AEImageObject
-(NSMutableArray*)countGridWithImageObjects:(NSMutableArray*)imageObjects {
    NSMutableArray *finalArray = [[NSMutableArray alloc]init];
    
    finalArray = [self startCountWithImageObjectsArray:imageObjects];
    
    return [self getFrames:finalArray];
}

//Данный метод производит расчет и принимает на вход массив объектов типа AEImageObject
-(NSMutableArray*) startCountWithImageObjectsArray:(NSMutableArray*)workingArray {
    if (workingArray.count == 1) {
        AEImageObject *imageObject = [workingArray objectAtIndex:0];
        
        if (imageObject.type == NarrowRectanglePortrait) {
            //обрезаем до квадрата
            CGFloat w = imageObject.size.width;
            CGFloat h = w;
            
            CGFloat scaleFactor = blockWidth/w;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject.frame = CGRectMake(0, 0, roundf(scaleFactor*w), roundf(scaleFactor*h));
            
            blockFrame = CGRectMake(0, 0, blockWidth, blockWidth);
            
            return workingArray;
        } else {
            //маштабируем
            CGFloat scaleH = maxHeight/imageObject.size.height;
            CGFloat scaleW = blockWidth/imageObject.size.width;
            
            CGFloat minScale = MIN(scaleH, scaleW);
            
            CGFloat nw1 = imageObject.size.width*minScale;
            CGFloat nh1 = imageObject.size.height*minScale;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject.frame = CGRectMake(0, 0, roundf(nw1), roundf(nh1));
            
            blockFrame = imageObject.frame;
            
            return workingArray;
        }
    }
    if (workingArray.count == 2) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
    
        //1 ситуация
        if (imageObject1.type == NarrowRectangleAlbum && imageObject2.type == NarrowRectangleAlbum) {
            
            //маштабируем по ширине блока
            CGFloat nw1 = blockWidth;
            CGFloat nh1 = blockWidth/imageObject1.size.width*imageObject1.size.height;
            CGFloat nh2 = blockWidth/imageObject2.size.width*imageObject2.size.height;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject1.frame = CGRectMake(0, 0, roundf(nw1), roundf(nh1));
            imageObject2.frame = CGRectMake(0, nh1+offsetP, roundf(nw1), roundf(nh2));
            
            blockFrame = CGRectMake(0, 0, blockWidth, imageObject2.frame.origin.y+imageObject2.frame.size.height);
            
            return workingArray;
        }
        
        //Остальные случаи - во всех остальных случиях мы будем использовать следующий алгоритм :
        CGFloat w1, h1, w2, h2;
        
        //Если фигура типа NarrowRectangleAlbum или NarrowRectanglePortrait - уменьшаем размеры до квадрата
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        //Скейлим второе изображение по высоте первого
        CGFloat scaleHeight = h1/h2;
        
        //Считаем новые размеры с учетом scale
        w2 = w2*scaleHeight;
        h2 = h2*scaleHeight;
        
        //Скейлим по ширине блока оба изображения
        CGFloat summWidth = w1+w2+offsetP;
        
        CGFloat scaleBlockWidth = blockWidth/summWidth;
        
        //Функция roundf() округляет float до ближайшего целого числа
        imageObject1.frame = CGRectMake(0, 0, roundf(scaleBlockWidth*w1), roundf(scaleBlockWidth*h1));
        imageObject2.frame = CGRectMake(imageObject1.frame.size.width+offsetP, 0, roundf(scaleBlockWidth*w2), roundf(scaleBlockWidth*h2));
        
        blockFrame = CGRectMake(0, 0, blockWidth, imageObject1.frame.size.height);
        return workingArray;
    }
    if (workingArray.count == 3) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        
        // 1 ситуация - 3 NRA
        if (imageObject1.type == NarrowRectangleAlbum && imageObject2.type == NarrowRectangleAlbum && imageObject3.type == NarrowRectangleAlbum) {
            
            //Считаем scale по длине для первого и затем присваиваем новые размеры
            CGFloat scaleBlockWidth1 = blockWidth/w1;
            w1 = scaleBlockWidth1*w1;
            h1 = scaleBlockWidth1*h1;
            
            //Считаем scale по длине для второго и затем присваиваем новые размеры
            CGFloat scaleBlockWidth2 = blockWidth/w2;
            w2 = scaleBlockWidth2*w2;
            h2 = scaleBlockWidth2*h2;
            
            //Считаем scale по длине для третьего и затем присваиваем новые размеры
            CGFloat scaleBlockWidth3 = blockWidth/w3;
            w3 = scaleBlockWidth3*w3;
            h3 = scaleBlockWidth3*h3;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
            imageObject2.frame = CGRectMake(0, h1+offsetP, roundf(w2), roundf(h2));
            imageObject3.frame = CGRectMake(0, imageObject2.frame.origin.y+h2+offsetP, roundf(w3), roundf(h3));
            
            blockFrame = CGRectMake(0, 0, imageObject1.frame.size.width, h1+h2+h3+(2*offsetP));
            return workingArray;
        }
        
        // 2 ситуация - 3 NRP
        if (imageObject1.type == NarrowRectanglePortrait && imageObject2.type == NarrowRectanglePortrait && imageObject3.type == NarrowRectanglePortrait) {
            
            //Считаем scale по ширина для второго и затем присваиваем новые размеры
            CGFloat scaleHeight2 = h1/h2;
            w2 = scaleHeight2*w2;
            h2 = scaleHeight2*h2;
            
            //Считаем scale по ширина для третьего и затем присваиваем новые размеры
            CGFloat scaleHeight3 = h1/h3;
            w3 = scaleHeight3*w3;
            h3 = scaleHeight3*h3;
            
            //Считаем суммарную длину для проверки
            CGFloat summWidth = w1+w2+w3+(offsetP*2);
            CGFloat scaleBlockWidth = blockWidth/summWidth;
            
            CGFloat heightWithScale = scaleBlockWidth*h1;
            
            if (heightWithScale > maxHeight) {
                //Если фигура типа NarrowRectangleAlbum или NarrowRectanglePortrait и не помещается на экране - уменьшаем размеры до квадрата
                CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
                w1 = size1.width;
                h1 = size1.height;
                
                CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
                w2 = size2.width;
                h2 = size2.height;
                
                CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
                w3 = size3.width;
                h3 = size3.height;
                
                //Скейлим второе изображение по высоте первого
                scaleHeight2 = h1/h2;
                w2 = w2*scaleHeight2;
                h2 = h2*scaleHeight2;
                
                //Скейлим третье изображение по высоте первого
                scaleHeight3 = h1/h3;
                w3 = w3*scaleHeight3;
                h3 = h3*scaleHeight3;
                
                //Скейлим по ширине блока оба изображения
                summWidth = w1+w2+w3+(offsetP*2);
                
                scaleBlockWidth = blockWidth/summWidth;
                
                //Считаем новые размеры
                w1 = scaleBlockWidth*w1;
                h1 = scaleBlockWidth*h1;
                w2 = scaleBlockWidth*w2;
                h2 = scaleBlockWidth*h2;
                w3 = scaleBlockWidth*w3;
                h3 = scaleBlockWidth*h3;
                
                //Функция roundf() округляет float до ближайшего целого числа
                imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
                imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
                imageObject3.frame = CGRectMake(w1+w2+(offsetP*2), 0, roundf(w3), roundf(h3));
                
                blockFrame = CGRectMake(0, 0, blockWidth, h1);
                return workingArray;
            } else {
                //Считаем новые размеры
                w1 = scaleBlockWidth*w1;
                h1 = scaleBlockWidth*h1;
                w2 = scaleBlockWidth*w2;
                h2 = scaleBlockWidth*h2;
                w3 = scaleBlockWidth*w3;
                h3 = scaleBlockWidth*h3;
                
                //Функция roundf() округляет float до ближайшего целого числа
                imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
                imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
                imageObject3.frame = CGRectMake(w1+w2+(offsetP*2), 0, roundf(w3), roundf(h3));
                
                blockFrame = CGRectMake(0, 0, blockWidth, h1);
                return workingArray;
            }
            
        }
        
        // 3 ситуация - смотрим на первое изображение
        if (imageObject1.type == NarrowRectangleAlbum || imageObject1.type == RectangleAlbum) {
            
            //Скейлим по длине блока первое изображение и присваиваем новые размеры
            CGFloat scaleBlockWidth = blockWidth/w1;
            w1 = scaleBlockWidth*w1;
            h1 = scaleBlockWidth*h1;
            
            CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
            w2 = size2.width;
            h2 = size2.height;
            
            CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
            w3 = size3.width;
            h3 = size3.height;
            
            //Скейлим третье по ширине второго
            CGFloat scaleHeight1 = h2/h3;
            w3 = scaleHeight1 *w3;
            h3 = scaleHeight1 *h3;
            
            //Скейлим второе и третье по длине блока
            CGFloat summWidthScale = blockWidth/(w2+w3+offsetP);
            w2 = w2*summWidthScale;
            h2 = h2*summWidthScale;
            w3 = w3*summWidthScale;
            h3 = h3*summWidthScale;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
            imageObject2.frame = CGRectMake(0, h1+offsetP, roundf(w2), roundf(h2));
            imageObject3.frame = CGRectMake(w2+offsetP, h1+offsetP, roundf(w3), roundf(h3));
            
            blockFrame = CGRectMake(0, 0, blockWidth, h1+h2+offsetP);
            
            return workingArray;
        } else if (imageObject1.type == NarrowRectanglePortrait || imageObject1.type == RectanglePortrait || imageObject1.type == Square) {
            
            w2 = [self CheckIfNarrowCropToSquare:imageObject2].width;
            h2 = [self CheckIfNarrowCropToSquare:imageObject2].height;
            
            w3 = [self CheckIfNarrowCropToSquare:imageObject3].width;
            h3 = [self CheckIfNarrowCropToSquare:imageObject3].height;
            
            //Скейлим длину третьего по длине второго
            CGFloat scaleWidth = w2/w3;
            w3 = scaleWidth*w3;
            h3 = scaleWidth*h3;
            
            //Скейлим по ширине первого сумму ширин второго и третьего и присваиваем новые размеры
            CGFloat scaleHeight = (h1-offsetP)/(h2+h3);
            w2 = scaleHeight*w2;
            h2 = scaleHeight*h2;
            w3 = scaleHeight*w3;
            h3 = scaleHeight*h3;
            
            //Скейлим по длине блока сумму длин первого и второго
            CGFloat scaleBlockWidth = blockWidth/(w1+w2);
            w1 = scaleBlockWidth*w1;
            h1 = scaleBlockWidth*h1;
            
            w2 = scaleBlockWidth*w2;
            h2 = scaleBlockWidth*h2;
            
            w3 = scaleBlockWidth*w3;
            h3 = scaleBlockWidth*h3;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h2+h3+offsetP));
            imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
            imageObject3.frame = CGRectMake(w1+offsetP, h2+offsetP, roundf(w3), roundf(h3));
            
            blockFrame = CGRectMake(0, 0, blockWidth, h1);
    
            return workingArray;
        }
    }
    if (workingArray.count == 4) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        AEImageObject *imageObject4 = [workingArray objectAtIndex:3];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3, w4, h4;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        w4 = imageObject4.size.width;
        h4 = imageObject4.size.height;
        
        //1 ситуация 4 NRP
        if (imageObject1.type == NarrowRectanglePortrait && imageObject2.type == NarrowRectanglePortrait && imageObject3.type == NarrowRectanglePortrait && imageObject4.type == NarrowRectanglePortrait) {
            
            //Считаем scale по ширине для второго и затем присваиваем новые размеры
            CGFloat scaleHeight2 = h1/h2;
            w2 = scaleHeight2*w2;
            h2 = scaleHeight2*h2;
            
            //Считаем scale по ширине для третьего и затем присваиваем новые размеры
            CGFloat scaleHeight3 = h1/h3;
            w3 = scaleHeight3*w3;
            h3 = scaleHeight3*h3;
            
            //Считаем scale по ширине для четвертого и затем присваиваем новые размеры
            CGFloat scaleHeight4 = h1/h4;
            w4 = scaleHeight4*w4;
            h4 = scaleHeight4*h4;
            
            //Считаем суммарную длину для проверки
            CGFloat summWidth = w1+w2+w3+w4+(offsetP*3);
            CGFloat scaleBlockWidth = blockWidth/summWidth;
            
            CGFloat heightWithScale = scaleBlockWidth*h1;
            
            if (heightWithScale > maxHeight) {
                //Если фигура типа NarrowRectangleAlbum или NarrowRectanglePortrait и не помещается на экране - уменьшаем размеры до квадрата
                CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
                w1 = size1.width;
                h1 = size1.height;
                
                CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
                w2 = size2.width;
                h2 = size2.height;
                
                CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
                w3 = size3.width;
                h3 = size3.height;
                
                CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
                w4 = size4.width;
                h4 = size4.height;
                
                //Скейлим второе изображение по высоте первого
                scaleHeight2 = h1/h2;
                w2 = w2*scaleHeight2;
                h2 = h2*scaleHeight2;
                
                //Скейлим третье изображение по высоте первого
                scaleHeight3 = h1/h3;
                w3 = w3*scaleHeight3;
                h3 = h3*scaleHeight3;
                
                //Скейлим четвертое изображение по высоте первого
                scaleHeight4 = h1/h4;
                w4 = w4*scaleHeight4;
                h4 = h4*scaleHeight4;
                
                //Скейлим по ширине блока оба изображения
                summWidth = w1+w2+w3+w4+(offsetP*3);
                
                scaleBlockWidth = blockWidth/summWidth;
                
                //Считаем новые размеры
                w1 = scaleBlockWidth*w1;
                h1 = scaleBlockWidth*h1;
                w2 = scaleBlockWidth*w2;
                h2 = scaleBlockWidth*h2;
                w3 = scaleBlockWidth*w3;
                h3 = scaleBlockWidth*h3;
                w4 = scaleBlockWidth*w4;
                h4 = scaleBlockWidth*h4;
                
                //Функция roundf() округляет float до ближайшего целого числа
                imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
                imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
                imageObject3.frame = CGRectMake(w1+w2+(offsetP*2), 0, roundf(w3), roundf(h3));
                imageObject4.frame = CGRectMake(w1+w2+w3+(offsetP*3), 0, roundf(w4), roundf(h4));
                
                blockFrame = CGRectMake(0, 0, blockWidth, h1);
                return workingArray;
            } else {
                //Считаем новые размеры
                w1 = scaleBlockWidth*w1;
                h1 = scaleBlockWidth*h1;
                w2 = scaleBlockWidth*w2;
                h2 = scaleBlockWidth*h2;
                w3 = scaleBlockWidth*w3;
                h3 = scaleBlockWidth*h3;
                w4 = scaleBlockWidth*w4;
                h4 = scaleBlockWidth*h4;
                
                //Функция roundf() округляет float до ближайшего целого числа
                imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
                imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
                imageObject3.frame = CGRectMake(w1+w2+(offsetP*2), 0, roundf(w3), roundf(h3));
                imageObject4.frame = CGRectMake(w1+w2+w3+(offsetP*3), 0, roundf(w4), roundf(h4));
                
                blockFrame = CGRectMake(0, 0, blockWidth, h1);
                return workingArray;
            }
        }
        
        //2 ситуация 4 NRA
        if (imageObject1.type == NarrowRectangleAlbum && imageObject2.type == NarrowRectangleAlbum && imageObject3.type == NarrowRectangleAlbum && imageObject4.type == NarrowRectangleAlbum) {
            
            //Считаем scale по длине для первого и затем присваиваем новые размеры
            CGFloat scaleBlockWidth1 = blockWidth/w1;
            w1 = scaleBlockWidth1*w1;
            h1 = scaleBlockWidth1*h1;
            
            //Считаем scale по длине для второго и затем присваиваем новые размеры
            CGFloat scaleBlockWidth2 = blockWidth/w2;
            w2 = scaleBlockWidth2*w2;
            h2 = scaleBlockWidth2*h2;
            
            //Считаем scale по длине для третьего и затем присваиваем новые размеры
            CGFloat scaleBlockWidth3 = blockWidth/w3;
            w3 = scaleBlockWidth3*w3;
            h3 = scaleBlockWidth3*h3;
            
            //Считаем scale по длине для четвертого и затем присваиваем новые размеры
            CGFloat scaleBlockWidth4 = blockWidth/w4;
            w4 = scaleBlockWidth4*w4;
            h4 = scaleBlockWidth4*h4;
            
            CGFloat summHeight = h1+h2+h3+h4+(offsetP*3);
            if (summHeight <= maxHeight) {
                NSLog(@"summHeight <= maxHeight");
                
                //Функция roundf() округляет float до ближайшего целого числа
                imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
                imageObject2.frame = CGRectMake(0, h1+offsetP, roundf(w2), roundf(h2));
                imageObject3.frame = CGRectMake(0, imageObject2.frame.origin.y+h2+offsetP, roundf(w3), roundf(h3));
                imageObject4.frame = CGRectMake(0, imageObject3.frame.origin.y+h3+offsetP, roundf(w4), roundf(h4));
                
                blockFrame = CGRectMake(0, 0, imageObject1.frame.size.width, h1+h2+h3+h4+(2*offsetP));
                return workingArray;
            } else {
                
                // обрезаем до квадрата а дальше построчно
                CGFloat commonValue = (blockWidth-offsetP)/2;
                
                imageObject1.frame = CGRectMake(0, 0, commonValue, commonValue);
                imageObject2.frame = CGRectMake(commonValue+offsetP, 0, commonValue, commonValue);
                imageObject3.frame = CGRectMake(0, commonValue+offsetP, commonValue, commonValue);
                imageObject4.frame = CGRectMake(commonValue+offsetP, commonValue+offsetP, commonValue, commonValue);
                
                blockFrame = CGRectMake(0, 0, (4*commonValue)+(3*offsetP), commonValue*2+offsetP);
                
                [self listenArray:workingArray];
                
                return workingArray;
            }
        }
        
        //3 ситуация 2 NRP
        if (imageObject1.type == NarrowRectanglePortrait && imageObject2.type == NarrowRectanglePortrait && imageObject3.type != RectanglePortrait && imageObject4.type != RectanglePortrait) {
            
            //Скейлим второе по ширине первого
            CGFloat scaleHeight = h1/h2;
            w2 = scaleHeight*w2;
            h2 = scaleHeight*h2;
            
            CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
            w3 = size3.width;
            h3 = size3.height;
            
            CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
            w4 = size4.width;
            h4 = size4.height;
            
            //Скейлим четвертое по длине третьего
            CGFloat scaleWidth = w3/w4;
            w4 = scaleWidth*w4;
            h4 = scaleWidth*h4;
            
            //Скейли суммарную ширину третьего и четвертого по ширине первого
            CGFloat scaleSummHeight = h1/(h3+h4+offsetP);
            w3 = scaleSummHeight*w3;
            h3 = scaleSummHeight*h3;
            w4 = scaleSummHeight*w4;
            h4 = scaleSummHeight*h4;
            
            //Скейлим суммарную длину по длине блока
            CGFloat scaleSummWidth = blockWidth/(w1+w2+w3+(offsetP*2));
            w1 = scaleSummWidth*w1;
            h1 = scaleSummWidth*h1;
            w2 = scaleSummWidth*w2;
            h2 = scaleSummWidth*h2;
            w3 = scaleSummWidth*w3;
            h3 = scaleSummWidth*h3;
            w4 = scaleSummWidth*w4;
            h4 = scaleSummWidth*h4;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
            imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
            imageObject3.frame = CGRectMake(w1+w2+(2*offsetP), 0, roundf(w3), roundf(h3));
            imageObject4.frame = CGRectMake(w1+w2+(2*offsetP), h3+offsetP, roundf(w4), roundf(h1-h3-offsetP));
            
            blockFrame = CGRectMake(0, 0, w1+w2+w3+(offsetP*2), h1);
            return workingArray;
        }
        
        
        //Если не сработали три предыдущие ситуации - построчно
        
        //Обрезаем фигуры, если требуется
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
        w3 = size3.width;
        h3 = size3.height;
        
        CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
        w4 = size4.width;
        h4 = size4.height;
        
        //Первая строка
        //Скейлим второе по высоте первого
        CGFloat scaleHeight2 = h1/h2;
        w2 = scaleHeight2*w2;
        h2 = scaleHeight2*h2;
        
        //Скейлим суммарную длину первого и второго по длине блока
        CGFloat scaleWidth1 = blockWidth/(w1+w2+offsetP);
        w1 = scaleWidth1*w1;
        h1 = scaleWidth1*h1;
        w2 = scaleWidth1*w2;
        h2 = scaleWidth1*h2;
        
        //Вторая строка
        //Скейлим четвертое по высоте третьего
        CGFloat scaleHeight4 = h3/h4;
        w4 = scaleHeight4*w4;
        h4 = scaleHeight4*h4;
        
        //Скейлим суммарную длину третьего и четвертого по длине блока
        CGFloat scaleWidth2 = blockWidth/(w3+w4+offsetP);
        w3 = scaleWidth2*w3;
        h3 = scaleWidth2*h3;
        w4 = scaleWidth2*w4;
        h4 = scaleWidth2*h4;
        
        imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
        imageObject2.frame = CGRectMake(roundf(w1)+offsetP, 0, roundf(w2), roundf(h2));
        imageObject3.frame = CGRectMake(0, roundf(h1)+offsetP, roundf(w3), roundf(h3));
        imageObject4.frame = CGRectMake(roundf(w3)+offsetP, roundf(h1)+offsetP, roundf(w4), roundf(h4));
        
        blockFrame = CGRectMake(0, 0, blockWidth, roundf(h1+h3+offsetP));
        
        return workingArray;
    }
    if (workingArray.count == 5) {
        
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        AEImageObject *imageObject4 = [workingArray objectAtIndex:3];
        AEImageObject *imageObject5 = [workingArray objectAtIndex:4];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3, w4, h4, w5, h5;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        w4 = imageObject4.size.width;
        h4 = imageObject4.size.height;
        w5 = imageObject5.size.width;
        h5 = imageObject5.size.height;
        
        //1 ситуация 5 NRP
        if (imageObject1.type == NarrowRectanglePortrait && imageObject2.type == NarrowRectanglePortrait && imageObject3.type == NarrowRectanglePortrait && imageObject4.type == NarrowRectanglePortrait && imageObject5.type == NarrowRectanglePortrait) {
            
            //Считаем scale по ширине для второго и затем присваиваем новые размеры
            CGFloat scaleHeight2 = h1/h2;
            w2 = scaleHeight2*w2;
            h2 = scaleHeight2*h2;
            
            //Считаем scale по ширине для третьего и затем присваиваем новые размеры
            CGFloat scaleHeight3 = h1/h3;
            w3 = scaleHeight3*w3;
            h3 = scaleHeight3*h3;
            
            //Считаем scale по ширине для четвертого и затем присваиваем новые размеры
            CGFloat scaleHeight4 = h1/h4;
            w4 = scaleHeight4*w4;
            h4 = scaleHeight4*h4;
            
            //Считаем scale по ширине для пятого и затем присваиваем новые размеры
            CGFloat scaleHeight5 = h1/h5;
            w5 = scaleHeight5*w5;
            h5 = scaleHeight5*h5;
            
            //Считаем суммарную длину для проверки
            CGFloat summWidth = w1+w2+w3+w4+w5+(offsetP*4);
            CGFloat scaleBlockWidth = blockWidth/summWidth;
            
            //Считаем новые размеры
            w1 = scaleBlockWidth*w1;
            h1 = scaleBlockWidth*h1;
            w2 = scaleBlockWidth*w2;
            h2 = scaleBlockWidth*h2;
            w3 = scaleBlockWidth*w3;
            h3 = scaleBlockWidth*h3;
            w4 = scaleBlockWidth*w4;
            h4 = scaleBlockWidth*h4;
            w5 = scaleBlockWidth*w5;
            h5 = scaleBlockWidth*h5;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
            imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
            imageObject3.frame = CGRectMake(w1+w2+(offsetP*2), 0, roundf(w3), roundf(h3));
            imageObject4.frame = CGRectMake(w1+w2+w3+(offsetP*3), 0, roundf(w4), roundf(h4));
            imageObject5.frame = CGRectMake(w1+w2+w3+w4+(offsetP*4), 0, roundf(w5), roundf(h5));
            
            blockFrame = CGRectMake(0, 0, blockWidth, h1);
            
            return workingArray;
        }
        
        //Если не первая ситуация - считаем построчно
        
        //Обрезаем фигуры, если требуется
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
        w3 = size3.width;
        h3 = size3.height;
        
        CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
        w4 = size4.width;
        h4 = size4.height;
        
        CGSize size5 = [self CheckIfNarrowCropToSquare:imageObject5];
        w5 = size5.width;
        h5 = size5.height;
        
        //Первая строка
        //Скейлим второе по высоте первого
        CGFloat scaleHeight2 = h1/h2;
        w2 = scaleHeight2*w2;
        h2 = scaleHeight2*h2;
        
        //Скейлим сумму первого и второго по длине блока
        CGFloat scaleWidth1 = blockWidth/(w1+w2+offsetP);
        w1 = scaleWidth1*w1;
        h1 = scaleWidth1*h1;
        w2 = scaleWidth1*w2;
        h2 = scaleWidth1*h2;
        
        //Вторая строка
        //Скейлим Четвертое по высоте третьего
        CGFloat scaleHeight4 = h3/h4;
        w4 = scaleHeight4*w4;
        h4 = scaleHeight4*h4;
        
        //Скейлим пятое по высоте третьего
        CGFloat scaleHeight5 = h3/h5;
        w5 = scaleHeight5*w5;
        h5 = scaleHeight5*h5;
        
        //Скейлим сумму длин второй строки по длине блока
        CGFloat scaleWidth2 = (blockWidth-offsetP*2)/(w3+w4+w5);
        w3 = scaleWidth2*w3;
        h3 = scaleWidth2*h3;
        w4 = scaleWidth2*w4;
        h4 = scaleWidth2*h4;
        w5 = scaleWidth2*w5;
        h5 = scaleWidth2*h5;
        
        imageObject1.frame = CGRectMake(0, 0, w1, h1);
        imageObject2.frame = CGRectMake(w1+offsetP, 0, w2, h2);
        imageObject3.frame = CGRectMake(0, h1+offsetP, w3, h3);
        imageObject4.frame = CGRectMake(w3+offsetP, h1+offsetP, w4, h4);
        imageObject5.frame = CGRectMake(w3+w4+offsetP*2, h1+offsetP, w5, h5);
        
        blockFrame = CGRectMake(0, 0, blockWidth, h1+h3+offsetP);
        
        return workingArray;
    }
    if (workingArray.count == 6) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        AEImageObject *imageObject4 = [workingArray objectAtIndex:3];
        AEImageObject *imageObject5 = [workingArray objectAtIndex:4];
        AEImageObject *imageObject6 = [workingArray objectAtIndex:5];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3, w4, h4, w5, h5, w6, h6;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        w4 = imageObject4.size.width;
        h4 = imageObject4.size.height;
        w5 = imageObject5.size.width;
        h5 = imageObject5.size.height;
        w6 = imageObject6.size.width;
        h6 = imageObject6.size.height;
        
        //1 ситуация 6 NRP
        if (imageObject1.type == NarrowRectanglePortrait && imageObject2.type == NarrowRectanglePortrait && imageObject3.type == NarrowRectanglePortrait && imageObject4.type == NarrowRectanglePortrait && imageObject5.type == NarrowRectanglePortrait && imageObject6.type == NarrowRectanglePortrait) {
            
            //Считаем scale по ширине для второго и затем присваиваем новые размеры
            CGFloat scaleHeight2 = h1/h2;
            w2 = scaleHeight2*w2;
            h2 = scaleHeight2*h2;
            
            //Считаем scale по ширине для третьего и затем присваиваем новые размеры
            CGFloat scaleHeight3 = h1/h3;
            w3 = scaleHeight3*w3;
            h3 = scaleHeight3*h3;
            
            //Считаем scale по ширине для четвертого и затем присваиваем новые размеры
            CGFloat scaleHeight4 = h1/h4;
            w4 = scaleHeight4*w4;
            h4 = scaleHeight4*h4;
            
            //Считаем scale по ширине для пятого и затем присваиваем новые размеры
            CGFloat scaleHeight5 = h1/h5;
            w5 = scaleHeight5*w5;
            h5 = scaleHeight5*h5;
            
            //Считаем scale по ширине для шестого и затем присваиваем новые размеры
            CGFloat scaleHeight6 = h1/h6;
            w6 = scaleHeight6*w6;
            h6 = scaleHeight6*h6;
            
            //Считаем суммарную длину для проверки
            CGFloat summWidth = w1+w2+w3+w4+w5+w6;
            CGFloat scaleBlockWidth = (blockWidth-offsetP*5)/summWidth;
            
            //Считаем новые размеры
            w1 = scaleBlockWidth*w1;
            h1 = scaleBlockWidth*h1;
            w2 = scaleBlockWidth*w2;
            h2 = scaleBlockWidth*h2;
            w3 = scaleBlockWidth*w3;
            h3 = scaleBlockWidth*h3;
            w4 = scaleBlockWidth*w4;
            h4 = scaleBlockWidth*h4;
            w5 = scaleBlockWidth*w5;
            h5 = scaleBlockWidth*h5;
            w6 = scaleBlockWidth*w6;
            h6 = scaleBlockWidth*h6;
            
            //Функция roundf() округляет float до ближайшего целого числа
            imageObject1.frame = CGRectMake(0, 0, roundf(w1), roundf(h1));
            imageObject2.frame = CGRectMake(w1+offsetP, 0, roundf(w2), roundf(h2));
            imageObject3.frame = CGRectMake(w1+w2+(offsetP*2), 0, roundf(w3), roundf(h3));
            imageObject4.frame = CGRectMake(w1+w2+w3+(offsetP*3), 0, roundf(w4), roundf(h4));
            imageObject5.frame = CGRectMake(w1+w2+w3+w4+(offsetP*4), 0, roundf(w5), roundf(h5));
            imageObject6.frame = CGRectMake(w1+w2+w3+w4+w5+(offsetP*5), 0, roundf(w6), roundf(h6));
            
            blockFrame = CGRectMake(0, 0, blockWidth, h1);
            
            return workingArray;
        }
        
        //Если не первая ситуация - считаем построчно
        
        //Обрезаем фигуры, если требуется
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
        w3 = size3.width;
        h3 = size3.height;
        
        CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
        w4 = size4.width;
        h4 = size4.height;
        
        CGSize size5 = [self CheckIfNarrowCropToSquare:imageObject5];
        w5 = size5.width;
        h5 = size5.height;
        
        CGSize size6 = [self CheckIfNarrowCropToSquare:imageObject6];
        w6 = size6.width;
        h6 = size6.height;
        
        //Первая строка
        //Скейлим второе по высоте первого
        CGFloat scaleHeight2 = h1/h2;
        w2 = scaleHeight2*w2;
        h2 = scaleHeight2*h2;
        
        //Cкейлим третье по высоте первого
        CGFloat scaleHeight3 = h1/h3;
        w3 = scaleHeight3*w3;
        h3 = scaleHeight3*h3;
        
        //Скейлим сумму первой строки по длине блока
        CGFloat scaleWidth1 = (blockWidth-offsetP*2)/(w1+w2+w3);
        w1 = scaleWidth1*w1;
        h1 = scaleWidth1*h1;
        w2 = scaleWidth1*w2;
        h2 = scaleWidth1*h2;
        w3 = scaleWidth1*w3;
        h3 = scaleWidth1*h3;
        
        //Вторая строка
        //Скейлим пятое по высоте четвертого
        CGFloat scaleHeight5 = h4/h5;
        w5 = scaleHeight5*w5;
        h5 = scaleHeight5*h5;
        
        //Скейлим шестое по высоте четвертого
        CGFloat scaleHeight6 = h4/h6;
        w6 = scaleHeight6*w6;
        h6 = scaleHeight6*h6;
        
        //Скейлим сумму длин второй строки по длине блока
        CGFloat scaleWidth2 = (blockWidth-offsetP*2)/(w4+w5+w6);
        w4 = scaleWidth2*w4;
        h4 = scaleWidth2*h4;
        w5 = scaleWidth2*w5;
        h5 = scaleWidth2*h5;
        w6 = scaleWidth2*w6;
        h6 = scaleWidth2*h6;
        
        imageObject1.frame = CGRectMake(0, 0, w1, h1);
        imageObject2.frame = CGRectMake(w1+offsetP, 0, w2, h2);
        imageObject3.frame = CGRectMake(w1+w2+offsetP*2, 0, w3, h3);
        
        imageObject4.frame = CGRectMake(0, h1+offsetP, w4, h4);
        imageObject5.frame = CGRectMake(w4+offsetP, h1+offsetP, w5, h5);
        imageObject6.frame = CGRectMake(w4+w5+offsetP*2, h1+offsetP, w6, h6);
        
        blockFrame = CGRectMake(0, 0, blockWidth, h1+h4+offsetP);
        
        return workingArray;
    }
    if (workingArray.count == 7) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        AEImageObject *imageObject4 = [workingArray objectAtIndex:3];
        AEImageObject *imageObject5 = [workingArray objectAtIndex:4];
        AEImageObject *imageObject6 = [workingArray objectAtIndex:5];
        AEImageObject *imageObject7 = [workingArray objectAtIndex:6];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3, w4, h4, w5, h5, w6, h6, w7, h7;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        w4 = imageObject4.size.width;
        h4 = imageObject4.size.height;
        w5 = imageObject5.size.width;
        h5 = imageObject5.size.height;
        w6 = imageObject6.size.width;
        h6 = imageObject6.size.height;
        w7 = imageObject7.size.width;
        h7 = imageObject7.size.height;
        
        //Обрезаем фигуры, если требуется
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
        w3 = size3.width;
        h3 = size3.height;
        
        CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
        w4 = size4.width;
        h4 = size4.height;
        
        CGSize size5 = [self CheckIfNarrowCropToSquare:imageObject5];
        w5 = size5.width;
        h5 = size5.height;
        
        CGSize size6 = [self CheckIfNarrowCropToSquare:imageObject6];
        w6 = size6.width;
        h6 = size6.height;
        
        CGSize size7 = [self CheckIfNarrowCropToSquare:imageObject7];
        w7 = size7.width;
        h7 = size7.height;
        
        //Первая строка
        //Скейлим второе по высоте первого
        CGFloat scaleHeight2 = h1/h2;
        w2 = scaleHeight2*w2;
        h2 = scaleHeight2*h2;
        
        //Cкейлим третье по высоте первого
        CGFloat scaleHeight3 = h1/h3;
        w3 = scaleHeight3*w3;
        h3 = scaleHeight3*h3;
        
        //Скейлим сумму первой строки по длине блока
        CGFloat scaleWidth1 = (blockWidth-offsetP*2)/(w1+w2+w3);
        w1 = scaleWidth1*w1;
        h1 = scaleWidth1*h1;
        w2 = scaleWidth1*w2;
        h2 = scaleWidth1*h2;
        w3 = scaleWidth1*w3;
        h3 = scaleWidth1*h3;
        
        //Вторая строка
        //Скейлим пятое по высоте четвертого
        CGFloat scaleHeight5 = h4/h5;
        w5 = scaleHeight5*w5;
        h5 = scaleHeight5*h5;
        
        //Скейлим шестое по высоте четвертого
        CGFloat scaleHeight6 = h4/h6;
        w6 = scaleHeight6*w6;
        h6 = scaleHeight6*h6;
        
        //Скейлим седьмое по высоте четвертого
        CGFloat scaleHeight7 = h4/h7;
        w7 = scaleHeight7*w7;
        h7 = scaleHeight7*h7;
        
        //Скейлим сумму длин второй строки по длине блока
        CGFloat scaleWidth2 = (blockWidth-offsetP*3)/(w4+w5+w6+w7);
        w4 = scaleWidth2*w4;
        h4 = scaleWidth2*h4;
        w5 = scaleWidth2*w5;
        h5 = scaleWidth2*h5;
        w6 = scaleWidth2*w6;
        h6 = scaleWidth2*h6;
        w7 = scaleWidth2*w7;
        h7 = scaleWidth2*h7;
        
        imageObject1.frame = CGRectMake(0, 0, w1, h1);
        imageObject2.frame = CGRectMake(w1+offsetP, 0, w2, h2);
        imageObject3.frame = CGRectMake(w1+w2+offsetP*2, 0, w3, h3);
        
        imageObject4.frame = CGRectMake(0, h1+offsetP, w4, h4);
        imageObject5.frame = CGRectMake(w4+offsetP, h1+offsetP, w5, h5);
        imageObject6.frame = CGRectMake(w4+w5+offsetP*2, h1+offsetP, w6, h6);
        imageObject7.frame = CGRectMake(w4+w5+w6+offsetP*3, h1+offsetP, w7, h7);
        
        blockFrame = CGRectMake(0, 0, blockWidth, h1+h4+offsetP);
        
        return workingArray;
    }
    if (workingArray.count == 8) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        AEImageObject *imageObject4 = [workingArray objectAtIndex:3];
        AEImageObject *imageObject5 = [workingArray objectAtIndex:4];
        AEImageObject *imageObject6 = [workingArray objectAtIndex:5];
        AEImageObject *imageObject7 = [workingArray objectAtIndex:6];
        AEImageObject *imageObject8 = [workingArray objectAtIndex:7];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3, w4, h4, w5, h5, w6, h6, w7, h7, w8, h8;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        w4 = imageObject4.size.width;
        h4 = imageObject4.size.height;
        w5 = imageObject5.size.width;
        h5 = imageObject5.size.height;
        w6 = imageObject6.size.width;
        h6 = imageObject6.size.height;
        w7 = imageObject7.size.width;
        h7 = imageObject7.size.height;
        w8 = imageObject8.size.width;
        h8 = imageObject8.size.height;
        
        //Обрезаем фигуры, если требуется
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
        w3 = size3.width;
        h3 = size3.height;
        
        CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
        w4 = size4.width;
        h4 = size4.height;
        
        CGSize size5 = [self CheckIfNarrowCropToSquare:imageObject5];
        w5 = size5.width;
        h5 = size5.height;
        
        CGSize size6 = [self CheckIfNarrowCropToSquare:imageObject6];
        w6 = size6.width;
        h6 = size6.height;
        
        CGSize size7 = [self CheckIfNarrowCropToSquare:imageObject7];
        w7 = size7.width;
        h7 = size7.height;
        
        CGSize size8 = [self CheckIfNarrowCropToSquare:imageObject8];
        w8 = size8.width;
        h8 = size8.height;
        
        //Первая строка
        //Скейлим второе по высоте первого
        CGFloat scaleHeight2 = h1/h2;
        w2 = scaleHeight2*w2;
        h2 = scaleHeight2*h2;
        
        //Cкейлим третье по высоте первого
        CGFloat scaleHeight3 = h1/h3;
        w3 = scaleHeight3*w3;
        h3 = scaleHeight3*h3;
        
        //Cкейлим четвертое по высоте первого
        CGFloat scaleHeight4 = h1/h4;
        w4 = scaleHeight4*w4;
        h4 = scaleHeight4*h4;
        
        //Скейлим сумму первой строки по длине блока
        CGFloat scaleWidth1 = (blockWidth-offsetP*3)/(w1+w2+w3+w4);
        w1 = scaleWidth1*w1;
        h1 = scaleWidth1*h1;
        w2 = scaleWidth1*w2;
        h2 = scaleWidth1*h2;
        w3 = scaleWidth1*w3;
        h3 = scaleWidth1*h3;
        w4 = scaleWidth1*w4;
        h4 = scaleWidth1*h4;
        
        //Вторая строка
        //Скейлим шестое по высоте пятого
        CGFloat scaleHeight6 = h5/h6;
        w6 = scaleHeight6*w6;
        h6 = scaleHeight6*h6;
        
        //Скейлим седьмое по высоте пятого
        CGFloat scaleHeight7 = h5/h7;
        w7 = scaleHeight7*w7;
        h7 = scaleHeight7*h7;
        
        //Скейлим восьмое по высоте пятого
        CGFloat scaleHeight8 = h5/h8;
        w8 = scaleHeight8*w8;
        h8 = scaleHeight8*h8;
        
        //Скейлим сумму длин второй строки по длине блока
        CGFloat scaleWidth2 = (blockWidth-offsetP*3)/(w5+w6+w7+w8);
        w5 = scaleWidth2*w5;
        h5 = scaleWidth2*h5;
        w6 = scaleWidth2*w6;
        h6 = scaleWidth2*h6;
        w7 = scaleWidth2*w7;
        h7 = scaleWidth2*h7;
        w8 = scaleWidth2*w8;
        h8 = scaleWidth2*h8;
        
        imageObject1.frame = CGRectMake(0, 0, w1, h1);
        imageObject2.frame = CGRectMake(w1+offsetP, 0, w2, h2);
        imageObject3.frame = CGRectMake(w1+w2+offsetP*2, 0, w3, h3);
        imageObject4.frame = CGRectMake(w1+w2+w3+offsetP*3, 0, w4, h4);
        
        imageObject5.frame = CGRectMake(0, h1+offsetP, w5, h5);
        imageObject6.frame = CGRectMake(w5+offsetP, h1+offsetP, w6, h6);
        imageObject7.frame = CGRectMake(w5+w6+offsetP*2, h1+offsetP, w7, h7);
        imageObject8.frame = CGRectMake(w5+w6+w7+offsetP*3, h1+offsetP, w8, h8);
        
        blockFrame = CGRectMake(0, 0, blockWidth, h1+h5+offsetP);
        
        return workingArray;
    }
    if (workingArray.count == 9) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        AEImageObject *imageObject4 = [workingArray objectAtIndex:3];
        AEImageObject *imageObject5 = [workingArray objectAtIndex:4];
        AEImageObject *imageObject6 = [workingArray objectAtIndex:5];
        AEImageObject *imageObject7 = [workingArray objectAtIndex:6];
        AEImageObject *imageObject8 = [workingArray objectAtIndex:7];
        AEImageObject *imageObject9 = [workingArray objectAtIndex:8];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3, w4, h4, w5, h5, w6, h6, w7, h7, w8, h8, w9, h9;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        w4 = imageObject4.size.width;
        h4 = imageObject4.size.height;
        w5 = imageObject5.size.width;
        h5 = imageObject5.size.height;
        w6 = imageObject6.size.width;
        h6 = imageObject6.size.height;
        w7 = imageObject7.size.width;
        h7 = imageObject7.size.height;
        w8 = imageObject8.size.width;
        h8 = imageObject8.size.height;
        w9 = imageObject9.size.width;
        h9 = imageObject9.size.height;
        
        //Обрезаем фигуры, если требуется
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
        w3 = size3.width;
        h3 = size3.height;
        
        CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
        w4 = size4.width;
        h4 = size4.height;
        
        CGSize size5 = [self CheckIfNarrowCropToSquare:imageObject5];
        w5 = size5.width;
        h5 = size5.height;
        
        CGSize size6 = [self CheckIfNarrowCropToSquare:imageObject6];
        w6 = size6.width;
        h6 = size6.height;
        
        CGSize size7 = [self CheckIfNarrowCropToSquare:imageObject7];
        w7 = size7.width;
        h7 = size7.height;
        
        CGSize size8 = [self CheckIfNarrowCropToSquare:imageObject8];
        w8 = size8.width;
        h8 = size8.height;
        
        CGSize size9 = [self CheckIfNarrowCropToSquare:imageObject9];
        w9 = size9.width;
        h9 = size9.height;
        
        //Первая строка
        //Скейлим второе по высоте первого
        CGFloat scaleHeight2 = h1/h2;
        w2 = scaleHeight2*w2;
        h2 = scaleHeight2*h2;
        
        //Cкейлим третье по высоте первого
        CGFloat scaleHeight3 = h1/h3;
        w3 = scaleHeight3*w3;
        h3 = scaleHeight3*h3;
        
        //Скейлим сумму первой строки по длине блока
        CGFloat scaleWidth1 = (blockWidth-offsetP*2)/(w1+w2+w3);
        w1 = scaleWidth1*w1;
        h1 = scaleWidth1*h1;
        w2 = scaleWidth1*w2;
        h2 = scaleWidth1*h2;
        w3 = scaleWidth1*w3;
        h3 = scaleWidth1*h3;
        
        //Вторая строка
        //Скейлим пятое по высоте четвертого
        CGFloat scaleHeight5 = h4/h5;
        w5 = scaleHeight5*w5;
        h5 = scaleHeight5*h5;
        
        //Скейлим шестое по высоте четвертого
        CGFloat scaleHeight6 = h4/h6;
        w6 = scaleHeight6*w6;
        h6 = scaleHeight6*h6;
        
        //Скейлим сумму длин второй строки по длине блока
        CGFloat scaleWidth2 = (blockWidth-offsetP*2)/(w4+w5+w6);
        w4 = scaleWidth2*w4;
        h4 = scaleWidth2*h4;
        w5 = scaleWidth2*w5;
        h5 = scaleWidth2*h5;
        w6 = scaleWidth2*w6;
        h6 = scaleWidth2*h6;
        
        //Третья строка
        //Скейлим восьмое по высоте седмого
        CGFloat scaleHeight8 = h7/h8;
        w8 = scaleHeight8*w8;
        h8 = scaleHeight8*h8;
        
        //Скейлим девятое по высоте седмого
        CGFloat scaleHeight9 = h7/h9;
        w9 = scaleHeight9*w9;
        h9 = scaleHeight9*h9;
        
        //Скейлим сумму длин третьей строки по длине блока
        CGFloat scaleWidth3 = (blockWidth-offsetP*2)/(w7+w8+w9);
        w7 = scaleWidth3*w7;
        h7 = scaleWidth3*h7;
        w8 = scaleWidth3*w8;
        h8 = scaleWidth3*h8;
        w9 = scaleWidth3*w9;
        h9 = scaleWidth3*h9;
        
        imageObject1.frame = CGRectMake(0, 0, w1, h1);
        imageObject2.frame = CGRectMake(w1+offsetP, 0, w2, h2);
        imageObject3.frame = CGRectMake(w1+w2+offsetP*2, 0, w3, h3);
        
        imageObject4.frame = CGRectMake(0, h1+offsetP, w4, h4);
        imageObject5.frame = CGRectMake(w4+offsetP, h1+offsetP, w5, h5);
        imageObject6.frame = CGRectMake(w4+w5+offsetP*2, h1+offsetP, w6, h6);
        
        imageObject7.frame = CGRectMake(0, h1+h4+offsetP*2, w7, h7);
        imageObject8.frame = CGRectMake(w7+offsetP, h1+h4+offsetP*2, w8, h8);
        imageObject9.frame = CGRectMake(w7+w8+offsetP*2, h1+h4+offsetP*2, w9, h9);
        
        blockFrame = CGRectMake(0, 0, blockWidth, h1+h4+h7+offsetP*2);
        
        return workingArray;
    }
    if (workingArray.count == 10) {
        AEImageObject *imageObject1 = [workingArray objectAtIndex:0];
        AEImageObject *imageObject2 = [workingArray objectAtIndex:1];
        AEImageObject *imageObject3 = [workingArray objectAtIndex:2];
        AEImageObject *imageObject4 = [workingArray objectAtIndex:3];
        AEImageObject *imageObject5 = [workingArray objectAtIndex:4];
        AEImageObject *imageObject6 = [workingArray objectAtIndex:5];
        AEImageObject *imageObject7 = [workingArray objectAtIndex:6];
        AEImageObject *imageObject8 = [workingArray objectAtIndex:7];
        AEImageObject *imageObject9 = [workingArray objectAtIndex:8];
        AEImageObject *imageObject10 = [workingArray objectAtIndex:9];
        
        //Получаем размеры
        CGFloat w1, h1, w2, h2, w3, h3, w4, h4, w5, h5, w6, h6, w7, h7, w8, h8, w9, h9, w10, h10;
        w1 = imageObject1.size.width;
        h1 = imageObject1.size.height;
        w2 = imageObject2.size.width;
        h2 = imageObject2.size.height;
        w3 = imageObject3.size.width;
        h3 = imageObject3.size.height;
        w4 = imageObject4.size.width;
        h4 = imageObject4.size.height;
        w5 = imageObject5.size.width;
        h5 = imageObject5.size.height;
        w6 = imageObject6.size.width;
        h6 = imageObject6.size.height;
        w7 = imageObject7.size.width;
        h7 = imageObject7.size.height;
        w8 = imageObject8.size.width;
        h8 = imageObject8.size.height;
        w9 = imageObject9.size.width;
        h9 = imageObject9.size.height;
        w10 = imageObject10.size.width;
        h10 = imageObject10.size.height;
        
        //Обрезаем фигуры, если требуется
        CGSize size1 = [self CheckIfNarrowCropToSquare:imageObject1];
        w1 = size1.width;
        h1 = size1.height;
        
        CGSize size2 = [self CheckIfNarrowCropToSquare:imageObject2];
        w2 = size2.width;
        h2 = size2.height;
        
        CGSize size3 = [self CheckIfNarrowCropToSquare:imageObject3];
        w3 = size3.width;
        h3 = size3.height;
        
        CGSize size4 = [self CheckIfNarrowCropToSquare:imageObject4];
        w4 = size4.width;
        h4 = size4.height;
        
        CGSize size5 = [self CheckIfNarrowCropToSquare:imageObject5];
        w5 = size5.width;
        h5 = size5.height;
        
        CGSize size6 = [self CheckIfNarrowCropToSquare:imageObject6];
        w6 = size6.width;
        h6 = size6.height;
        
        CGSize size7 = [self CheckIfNarrowCropToSquare:imageObject7];
        w7 = size7.width;
        h7 = size7.height;
        
        CGSize size8 = [self CheckIfNarrowCropToSquare:imageObject8];
        w8 = size8.width;
        h8 = size8.height;
        
        CGSize size9 = [self CheckIfNarrowCropToSquare:imageObject9];
        w9 = size9.width;
        h9 = size9.height;
        
        CGSize size10 = [self CheckIfNarrowCropToSquare:imageObject10];
        w10 = size10.width;
        h10 = size10.height;
        
        //Первая строка
        //Скейлим второе по высоте первого
        CGFloat scaleHeight2 = h1/h2;
        w2 = scaleHeight2*w2;
        h2 = scaleHeight2*h2;
        
        //Cкейлим третье по высоте первого
        CGFloat scaleHeight3 = h1/h3;
        w3 = scaleHeight3*w3;
        h3 = scaleHeight3*h3;
        
        //Скейлим сумму первой строки по длине блока
        CGFloat scaleWidth1 = (blockWidth-offsetP*2)/(w1+w2+w3);
        w1 = scaleWidth1*w1;
        h1 = scaleWidth1*h1;
        w2 = scaleWidth1*w2;
        h2 = scaleWidth1*h2;
        w3 = scaleWidth1*w3;
        h3 = scaleWidth1*h3;
        
        //Вторая строка
        //Скейлим пятое по высоте четвертого
        CGFloat scaleHeight5 = h4/h5;
        w5 = scaleHeight5*w5;
        h5 = scaleHeight5*h5;
        
        //Скейлим шестое по высоте четвертого
        CGFloat scaleHeight6 = h4/h6;
        w6 = scaleHeight6*w6;
        h6 = scaleHeight6*h6;
        
        //Скейлим сумму длин второй строки по длине блока
        CGFloat scaleWidth2 = (blockWidth-offsetP*2)/(w4+w5+w6);
        w4 = scaleWidth2*w4;
        h4 = scaleWidth2*h4;
        w5 = scaleWidth2*w5;
        h5 = scaleWidth2*h5;
        w6 = scaleWidth2*w6;
        h6 = scaleWidth2*h6;
        
        //Третья строка
        //Скейлим восьмое по высоте седмого
        CGFloat scaleHeight8 = h7/h8;
        w8 = scaleHeight8*w8;
        h8 = scaleHeight8*h8;
        
        //Скейлим девятое по высоте седмого
        CGFloat scaleHeight9 = h7/h9;
        w9 = scaleHeight9*w9;
        h9 = scaleHeight9*h9;
        
        //Скейлим десятое по высоте седмого
        CGFloat scaleHeight10 = h7/h10;
        w10 = scaleHeight10*w10;
        h10 = scaleHeight10*h10;
        
        //Скейлим сумму длин третьей строки по длине блока
        CGFloat scaleWidth3 = (blockWidth-offsetP*3)/(w7+w8+w9+w10);
        w7 = scaleWidth3*w7;
        h7 = scaleWidth3*h7;
        w8 = scaleWidth3*w8;
        h8 = scaleWidth3*h8;
        w9 = scaleWidth3*w9;
        h9 = scaleWidth3*h9;
        w10 = scaleWidth3*w10;
        h10 = scaleWidth3*h10;
        
        imageObject1.frame = CGRectMake(0, 0, w1, h1);
        imageObject2.frame = CGRectMake(w1+offsetP, 0, w2, h2);
        imageObject3.frame = CGRectMake(w1+w2+offsetP*2, 0, w3, h3);
        
        imageObject4.frame = CGRectMake(0, h1+offsetP, w4, h4);
        imageObject5.frame = CGRectMake(w4+offsetP, h1+offsetP, w5, h5);
        imageObject6.frame = CGRectMake(w4+w5+offsetP*2, h1+offsetP, w6, h6);
        
        imageObject7.frame = CGRectMake(0, h1+h4+offsetP*2, w7, h7);
        imageObject8.frame = CGRectMake(w7+offsetP, h1+h4+offsetP*2, w8, h8);
        imageObject9.frame = CGRectMake(w7+w8+offsetP*2, h1+h4+offsetP*2, w9, h9);
        imageObject10.frame = CGRectMake(w7+w8+w9+offsetP*3, h1+h4+offsetP*2, w10, h10);
        
        blockFrame = CGRectMake(0, 0, blockWidth, h1+h4+h7+offsetP*2);
        
        return workingArray;
    }
    
    return nil;
}

//Здесь осуществляется выбор типа фигуры для расчета - на вход подаем объект типа AEImageSizeObject (размеры изображения)
-(ShapeType)getShapeType:(AEImageSizeObject*)imageSizeObject {
    //Считаем отношение
    CGFloat ratio = imageSizeObject.width/imageSizeObject.height; //ratio - отношение
    
    NSLog(@"ratio: %f", ratio);
    //Начинаем определять тип фигуры
    
    if (ratio < 2.99 && ratio > 1) {
        /* RectangleAlbum
         ______________
         |              |
         |              |
         |              |
         |______________|
         
         соотношение сторон меньше чем 3:1 но больше чем 1:1
         
         */
        
        return RectangleAlbum;
    }
    
    if (ratio > 0.34 && ratio < 1) {
        /* RectanglePortrait
         __________
         |          |
         |          |
         |          |
         |          |
         |          |
         |          |
         |__________|
         
         соотношение сторон больше чем 1:3 но меньше чем 1:1
         
         */
        
        return RectanglePortrait;
    }
    
    if (ratio > 2.99) {
        /* NarrowRectangleAlbum
         _______________________
         |                       |
         |                       |
         |                       |
         |_______________________|
         
         соотношение сторон Больше чем 3:1
         
         */
        
        return NarrowRectangleAlbum;
    }
    
    if (ratio <= 0.34) {
        /* NarrowRectanglePortrait
         __________
         |          |
         |          |
         |          |
         |          |
         |          |
         |          |
         |          |
         |          |
         |          |
         |__________|
         
         
         соотношение сторон меньше чем 1:3
         
         */
        
        return NarrowRectanglePortrait;
    }
    
    if (ratio == 1) {
        /* Square
         ________
         |        |
         |        |
         |        |
         |________|
         
         соотношение сторон равно 1:1
         
         */
        
        return Square;
    }
    return nil;
}

//Данный метод уменьшает размеры до квадрата если фигура типа NarrowRectangleAlbum или NarrowRectanglePortrait
-(CGSize)CheckIfNarrowCropToSquare:(AEImageObject*)imageObject {
    CGFloat w, h;
    w = imageObject.size.width;
    h = imageObject.size.height;
    
    switch (imageObject.type) {
        case NarrowRectangleAlbum:
            w = h;
            break;
        case NarrowRectanglePortrait:
            h = w;
            break;
        default:
            break;
    }
    return CGSizeMake(w, h);
}

//Данный метод перебирает массив объектов типа AEImageObject и возвращает только рамки изображений
-(NSMutableArray*) getFrames:(NSMutableArray*)array {
    NSMutableArray *frames = [[NSMutableArray alloc]init];
    for (AEImageObject *imageObject in array) {
        [frames addObject:NSStringFromCGRect(imageObject.frame)];
    }
    return frames;
}

-(void)listenArray:(NSMutableArray*)arrayToListen {
    for (AEImageObject *imageObject in arrayToListen) {
        NSLog(@"{");
        NSLog(@"imageObject.width: %f", imageObject.size.width);
        NSLog(@"imageObject.height: %f", imageObject.size.height);
        NSLog(@"imageObject.type: %u", imageObject.type);
        NSLog(@"imageObject.frame: %@", NSStringFromCGRect(imageObject.frame));
        NSLog(@"}");
    }
}

@end
