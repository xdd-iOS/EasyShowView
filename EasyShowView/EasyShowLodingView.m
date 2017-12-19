//
//  EasyShowLodingView.m
//  EasyShowViewDemo
//
//  Created by nf on 2017/12/14.
//  Copyright © 2017年 chenliangloveyou. All rights reserved.
//

#import "EasyShowLodingView.h"
#import "UIView+EasyShowExt.h"
#import "EasyShowBgView.h"

@interface EasyLodingLabel :UILabel
- (instancetype)initWithContentInset:(UIEdgeInsets)contentInset ;
@property (nonatomic) UIEdgeInsets contentInset;
@end

@implementation EasyLodingLabel
- (instancetype)initWithContentInset:(UIEdgeInsets)contentInset
{
    if (self = [super init]) {
        _contentInset = contentInset ;
    }
    return self ;
}
- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    NSString *tempString = self.text;
    self.text = @"";
    self.text = tempString;
}
- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    UIEdgeInsets insets = self.contentInset;
    CGRect rect = [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, insets)
                    limitedToNumberOfLines:numberOfLines];
    
    rect.origin.x    -= insets.left;
    rect.origin.y    -= insets.top;
    rect.size.width  += (insets.left + insets.right);
    rect.size.height += (insets.top + insets.bottom);
    
    return rect;
}
-(void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.contentInset)];
}
@end


@interface EasyShowLodingView()<CAAnimationDelegate>

@property (nonatomic,strong)EasyShowOptions *options ;

@property (nonatomic,strong)NSString *showText ;//展示的文字
@property (nonatomic,strong)UIImage *showImage ;//展示的图片

@property (nonatomic,strong)UIView *lodingBgView ;//上面放着 textlabel 和 imageview
@property (nonatomic,strong)UILabel *textLabel ;
@property (nonatomic,strong)UIImageView *imageView ;

@property (nonatomic,strong)UIActivityIndicatorView *imageViewIndeicator ;


@end


@implementation EasyShowLodingView


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor =  [UIColor clearColor]; // [UIColor greenColor] ;//
    }
    return self ;
}

- (void)showViewWithSuperView:(UIView *)superView
{
    //展示视图的frame
    
    CGSize imageSize = CGSizeZero ;
    switch (self.options.lodingShowType) {
        case LodingShowTypeTurnAround:
        case LodingShowTypeTurnAroundLeft:
        case LodingShowTypeIndicator:
        case LodingShowTypeIndicatorLeft:
            imageSize = CGSizeMake(EasyShowLodingImageWH, EasyShowLodingImageWH);
            break;
        case LodingShowTypePlayImages:
        case LodingShowTypePlayImagesLeft:
        {
            NSAssert(self.options.lodingPlayImagesArray, @"you should set a image array!") ;
            UIImage *image = self.options.lodingPlayImagesArray.firstObject ;
            CGSize tempSize = image.size ;
            if (tempSize.height > EasyShowLodingImageMaxWH) {
                tempSize.height = EasyShowLodingImageMaxWH ;
            }
            if (tempSize.width > EasyShowLodingImageMaxWH) {
                tempSize.width = EasyShowLodingImageMaxWH ;
            }
            imageSize = tempSize ;
        }break ;
        case LodingShowTypeImageUpturn:
        case LodingShowTypeImageUpturnLeft:
        case LodingShowTypeImageAround:
        case LodingShowTypeImageAroundLeft:
        {
            CGSize tempSize = self.showImage.size ;
            if (tempSize.height > EasyShowLodingImageMaxWH) {
                tempSize.height = EasyShowLodingImageMaxWH ;
            }
            if (tempSize.width > EasyShowLodingImageMaxWH) {
                tempSize.width = EasyShowLodingImageMaxWH ;
            }
            imageSize = tempSize ;
        }break ;
        default:
            break;
    }

    
    if (!ISEMPTY(self.showText)) {
        self.textLabel.text = self.showText ;
    }
    
    CGFloat textMaxWidth = EasyShowLodingMaxWidth - (self.options.lodingShowType%2?:(EasyShowLodingImageWH+EasyShowLodingImageEdge*2)) ;//当为左右形式的时候减去图片的宽度
    CGSize textSize = [self.textLabel sizeThatFits:CGSizeMake(textMaxWidth, MAXFLOAT)];
    if (ISEMPTY(self.showText)) {
        textSize = CGSizeZero ;
    }
   
    //显示区域的宽高
    CGSize displayAreaSize = CGSizeZero ;
    if (self.options.lodingShowType%2) {
        //左右形式
        displayAreaSize.width = imageSize.width + EasyShowLodingImageEdge*2 + textSize.width ;
        displayAreaSize.height = MAX(imageSize.height+ EasyShowLodingImageEdge*2, textSize.height) ;
    }
    else{
        //上下形式
        displayAreaSize.width = MAX(imageSize.width+2*EasyShowLodingImageEdge, textSize.width);
        displayAreaSize.height = imageSize.height+2*EasyShowLodingImageEdge + textSize.height ;
    }

    
//    CGRect displayAreaRect = CGRectZero ;//显示区域
    if (self.options.lodingSuperViewReceiveEvent) {
        //父视图能够接受事件 。 显示区域的大小=self的大小=displayAreaSize

        [self setFrame:CGRectMake((SCREEN_WIDTH-displayAreaSize.width)/2, (SCREEN_HEIGHT-displayAreaSize.height)/2, displayAreaSize.width, displayAreaSize.height)];
    }
    else{
        //父视图不能接收-->self的大小应该为superview的大小。来遮盖
        
        [self setFrame: CGRectMake(0, 0, superView.width, superView.height)] ;
      
        self.lodingBgView.center = self.center ;

    }
    
    self.lodingBgView.frame = CGRectMake(0,0, displayAreaSize.width,displayAreaSize.height) ;
    if (!self.options.lodingSuperViewReceiveEvent) {
        self.lodingBgView.center = self.center ;

    }
    
    self.imageView.frame = CGRectMake(EasyShowLodingImageEdge, EasyShowLodingImageEdge, imageSize.width, imageSize.height) ;
    if (!(self.options.lodingShowType%2)) {
        self.imageView.centerX = self.lodingBgView.centerX ;
    }
   
    CGFloat textLabelX = 0 ;
    CGFloat textLabelY = 0 ;
    if (self.options.lodingShowType%2) {//左右形式
        textLabelX = self.imageView.right  ;
        textLabelY =  (self.lodingBgView.height-textSize.height)/2 ;
    }
    else{
        textLabelX = 0 ;
        textLabelY = self.imageView.bottom + EasyShowLodingImageEdge ;
    }
    self.textLabel.frame = CGRectMake(textLabelX, textLabelY, textSize.width, textSize.height );
    
    [superView addSubview:self];

    switch (self.options.lodingShowType) {
        case LodingShowTypeTurnAround:
        case LodingShowTypeTurnAroundLeft:
            [self drawAnimationImageViewLoding];
            break;
        case LodingShowTypeIndicator:
        case LodingShowTypeIndicatorLeft:
            [self.imageView addSubview:self.imageViewIndeicator];
            break ;
        case LodingShowTypePlayImages:
        case LodingShowTypePlayImagesLeft:
        {
            UIImage *tempImage  = self.options.lodingPlayImagesArray.firstObject ;
            self.imageView.image = tempImage ;
        }
            break ;
        case LodingShowTypeImageUpturn:
        case LodingShowTypeImageUpturnLeft:
            
            self.imageView.image = _showImage ;
            
            break ;
        case LodingShowTypeImageAround:
        case LodingShowTypeImageAroundLeft:
            break ;
        default:
            break;
    }
    
    
    void (^completion)(void) = ^{
        switch (self.options.lodingShowType) {
            case LodingShowTypeTurnAround:
            case LodingShowTypeTurnAroundLeft:
                [self drawAnimiationImageView:NO];
                break;
            case LodingShowTypeIndicator:
            case LodingShowTypeIndicatorLeft:
                [self.imageViewIndeicator startAnimating];
                break ;
            case LodingShowTypePlayImages:
            case LodingShowTypePlayImagesLeft:
            {
                NSMutableArray *tempArray= [NSMutableArray arrayWithCapacity:20];
                for (int i = 0 ; i < self.options.lodingPlayImagesArray.count; i++) {
                    UIImage *img = self.options.lodingPlayImagesArray[i] ;
                    if ([img isKindOfClass:[UIImage class]]) {
                        [tempArray addObject:img];
                    }
                }
                self.imageView.animationImages = tempArray ;
                self.imageView.animationDuration = self.options.showAnimationTime ;
                self.imageView.animationRepeatCount = NSIntegerMax ;
                [self.imageView startAnimating];
                
            }break ;
            case LodingShowTypeImageUpturn:
            case LodingShowTypeImageUpturnLeft:
                [self drawAnimiationImageView:YES];
                break ;
            case LodingShowTypeImageAround:
            case LodingShowTypeImageAroundLeft:
                break ;
            default:
                break;
        }
    };
   
    
    switch (self.options.lodingAnimationType) {
        case lodingAnimationTypeNone:
            completion() ;
            break;
        case lodingAnimationTypeBounce:
            [self showBounceAnimationStart:YES completion:completion];
            break ;
        case lodingAnimationTypeFade:
            [self showFadeAnimationStart:YES completion:completion ] ;
            break ;
        default:
            break;
    }
    
}

- (void)removeSelfFromSuperView
{
    void (^completion)(void) = ^{
        [self removeFromSuperview];
    };
    switch (self.options.lodingAnimationType) {
        case lodingAnimationTypeNone:
            completion() ;
            break;
        case lodingAnimationTypeBounce:
            [self showBounceAnimationStart:NO completion:completion];
            break ;
        case lodingAnimationTypeFade:
            [self showFadeAnimationStart:NO completion:completion ] ;
            break ;
        default:
            break;
    }
}



- (EasyShowOptions *)options
{
    if (nil == _options) {
        _options = [EasyShowOptions sharedEasyShowOptions];
    }
    return _options ;
}
- (UIView *)lodingBgView
{
    if (nil == _lodingBgView) {
        _lodingBgView = [[UIView alloc]init] ;
        _lodingBgView.backgroundColor = self.options.lodingBackgroundColor ;
        [self addSubview:_lodingBgView];
    }
    return _lodingBgView ;
}
- (UIImageView *)imageView
{
    if (nil == _imageView) {
        _imageView = [[UIImageView alloc]init];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.tintColor = self.options.lodingTintColor ;
        [self.lodingBgView addSubview:_imageView];
    }
    return _imageView ;
}
- (UILabel *)textLabel
{
    if (nil == _textLabel) {
        _textLabel = [[EasyLodingLabel alloc]initWithContentInset:UIEdgeInsetsMake(10, 20, 10, 20)];
        _textLabel.textColor = self.options.alertTitleColor;
        _textLabel.font = self.options.textFount ;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textAlignment = NSTextAlignmentCenter ;
        _textLabel.numberOfLines = 0 ;
        [self.lodingBgView addSubview:_textLabel];
    }
    return _textLabel ;
}

- (UIActivityIndicatorView *)imageViewIndeicator
{
    if (nil == _imageViewIndeicator) {
        UIActivityIndicatorViewStyle style = self.options.lodingShowType%2 ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleWhiteLarge ;
        _imageViewIndeicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        _imageViewIndeicator.tintColor = self.options.alertTitleColor ;
        _imageViewIndeicator.color = self.options.alertTitleColor ;
        _imageViewIndeicator.backgroundColor = [UIColor clearColor];
        _imageViewIndeicator.frame = self.imageView.bounds ;
    }
    return _imageViewIndeicator ;
}
// 转圈动画
- (void)drawAnimiationImageView:(BOOL)isImageView
{
    NSString *keyPath = isImageView ? @"transform.rotation.y" : @"transform.rotation.z" ;
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:keyPath];
    animation.fromValue=@(0);
    animation.toValue=@(M_PI*2);
    animation.duration=isImageView ? 1.3 : .8;
    animation.repeatCount=HUGE;
    animation.fillMode=kCAFillModeForwards;
    animation.removedOnCompletion=NO;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.imageView.layer addAnimation:animation forKey:@"animation"];
}


- (void)showFadeAnimationStart:(BOOL)isStart completion:(void(^)(void))completion
{
    self.alpha = isStart ? 0.1f : 1.0f;
    [UIView animateWithDuration:self.options.showAnimationTime animations:^{
        self.alpha = isStart ? 1.0 : 0.1f ;
    } completion:^(BOOL finished) {
        if (completion) {
            completion() ;
        }
    }];
}
- (void)showBounceAnimationStart:(BOOL)isStart completion:(void(^)(void))completion
{
    if (isStart) {
        CAKeyframeAnimation *popAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        popAnimation.duration = self.options.showAnimationTime ;
        popAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.01f, 0.01f, 1.0f)],
                                [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05f, 1.05f, 1.0f)],
                                [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95f, 0.95f, 1.0f)],
                                [NSValue valueWithCATransform3D:CATransform3DIdentity]];
        popAnimation.keyTimes = @[@0.2f, @0.5f, @0.75f, @1.0f];
        popAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                         [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                         [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        popAnimation.delegate = self ;
        [popAnimation setValue:completion forKey:@"handler"];
        [self.layer addAnimation:popAnimation forKey:nil];
        return ;
    }
    CABasicAnimation *bacAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    bacAnimation.duration = self.options.showAnimationTime ;
    bacAnimation.beginTime = .0;
    bacAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.4f :0.3f :0.5f :-0.5f];
    bacAnimation.fromValue = [NSNumber numberWithFloat:1.0f];
    bacAnimation.toValue = [NSNumber numberWithFloat:0.0f];
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[bacAnimation];
    animationGroup.duration =  bacAnimation.duration;
    animationGroup.removedOnCompletion = NO;
    animationGroup.fillMode = kCAFillModeForwards;
    
    animationGroup.delegate = self ;
    [animationGroup setValue:completion forKey:@"handler"];
    [self.layer addAnimation:animationGroup forKey:nil];
   
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    void(^completion)(void) = [anim valueForKey:@"handler"];
    if (completion) {
        completion();
    }
}
//加载loding的动画
- (void)drawAnimationImageViewLoding
{
    CGPoint centerPoint= CGPointMake(self.imageView.width/2.0f, self.imageView.height/2.0f) ;
    UIBezierPath *beizPath=[UIBezierPath bezierPathWithArcCenter:centerPoint radius:centerPoint.x startAngle:-M_PI_2 endAngle:M_PI_2 clockwise:YES];
    CAShapeLayer *centerLayer=[CAShapeLayer layer];
    centerLayer.path=beizPath.CGPath;
    centerLayer.fillColor=[UIColor clearColor].CGColor;//填充色
    centerLayer.strokeColor=self.options.lodingTintColor.CGColor;//边框颜色
    centerLayer.lineWidth=2.0f;
    centerLayer.lineCap=kCALineCapRound;//线框类型
    
    [self.imageView.layer addSublayer:centerLayer];
    
}






+ (void)showLodingWithText:(NSString *)text
                    inView:(UIView *)view
                     image:(UIImage *)image
{
    
    if (nil == view) {
        NSAssert(NO, @"there shoud have a superview");
        return ;
    }
    NSAssert([NSThread isMainThread], @"needs to be accessed on the main thread.");
    
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
        });
    }
    
    //显示之前---->隐藏还在显示的视图
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            EasyShowView *showView = (EasyShowView *)subview ;
            [showView removeSelfFromSuperView];
        }
    }
    
    EasyShowLodingView *showView = [[EasyShowLodingView alloc] initWithFrame:CGRectZero];
    showView.showText = text ;
    showView.showImage = image ;
    [showView showViewWithSuperView:view];
    
}


+ (void)showLoding
{
    [self showLodingText:@""];
}
+ (void)showLodingText:(NSString *)text
{
    UIView *showView = kTopViewController.view ;
    [self showLodingText:text inView:showView];
}
+ (void)showLodingText:(NSString *)text inView:(UIView *)superView
{
    [self showLodingText:text image:nil inView:superView];
}
+ (void)showLodingText:(NSString *)text image:(UIImage *)image
{
    UIView *showView = kTopViewController.view ;
    [self showLodingText:text image:image inView:showView];
}
+ (void)showLodingText:(NSString *)text image:(UIImage *)image inView:(UIView *)superView
{
    [self showLodingWithText:text inView:superView image:image];
}


+ (void)hidenLoding
{
    UIView *showView = kTopViewController.view ;
    [self hidenLoingInView:showView];
}
+ (void)hidenAllLoding
{
    
}
+ (void)hidenLoingInView:(UIView *)superView
{
    NSEnumerator *subviewsEnum = [superView.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            EasyShowView *showView = (EasyShowView *)subview ;
            [showView removeSelfFromSuperView];
        }
    }
}



@end
