//
//  AEGridCounter.h
//  NewImageGridView
//
//  Created by АЛЕКСАНДР on 14.01.14.
//  Copyright (c) 2014 АЛЕКСАНДР. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef enum {
    RectangleAlbum,
    RectanglePortrait,
    NarrowRectangleAlbum,
    NarrowRectanglePortrait,
    Square
} ShapeType;

/* Справка для Алексея
 
     RectangleAlbum - прямоугольник Альбомный
     RectanglePortrait - прямоугольник Портретный
     NarrowRectangleAlbum - узкий прямоугольник Альбомный
     NarrowRectanglePortrait - узкий прямоугольник Портретный
     Square - квадрат
*/

//Создадим обьект для хранения переменных
@interface AEImageSizeObject : NSObject
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@end

@interface AEGridCounter : NSObject {
    int maxHeight;
    int blockWidth;
    int offsetP;
    CGRect blockFrame;
}

//Рамка блока
@property (nonatomic) CGRect blockFrame;

//Singleton
+ (AEGridCounter *)shared;

//Return Frames Array

//Данный метод принимает на вход массив изображений и параметры блока
-(NSMutableArray*)countGrid:(NSMutableArray*)images blockWidth:(int)blockW offset:(int)offset;

-(NSMutableArray*)countGridWithSizes:(NSMutableArray *)imageSizes blockWidth:(int)blockW offset:(int)offset;

@end
