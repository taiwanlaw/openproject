import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {Component, ChangeDetectionStrategy, Injector, OnInit, OnDestroy, SimpleChanges, ChangeDetectorRef, ElementRef, ViewChild} from '@angular/core';
import {CustomTextEditFieldService} from "core-app/modules/grids/widgets/custom-text/custom-text-edit-field.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {filter} from 'rxjs/operators';
import {GridAreaService} from "core-app/modules/grids/grid/area.service";
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  templateUrl: './custom-text.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    CustomTextEditFieldService
  ]
})
export class WidgetCustomTextComponent extends AbstractWidgetComponent implements OnInit, OnDestroy {
  protected currentRawText:string;
  public customText:SafeHtml;

  @ViewChild('displayContainer', { static: false }) readonly displayContainer:ElementRef;

  constructor (protected i18n:I18nService,
               protected injector:Injector,
               public handler:CustomTextEditFieldService,
               protected cdr:ChangeDetectorRef,
               readonly sanitization:DomSanitizer,
               protected layout:GridAreaService) {
    super(i18n, injector);
  }

  ngOnInit():void {
    this.setupVariables(true);

    this
      .handler
      .valueChanged$
      .pipe(
        untilComponentDestroyed(this),
        filter(value => value !== this.resource.options['text'])
      ).subscribe(newText => {
        let changeset = this.setChangesetOptions({ text: { raw: newText } });
        this.resourceChanged.emit(changeset);
      });
  }

  ngOnDestroy():void {
    // comply to interface
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.resource.currentValue.options.text.raw !== this.currentRawText) {
      this.setupVariables();

      this.cdr.detectChanges();
    }
  }

  public activate(event:MouseEvent) {
    // Prevent opening the edit mode if a link was clicked
    if (this.clickedElementIsLinkWithinDisplayContainer(event)) {
      return;
    }

    // load the attachments so that they are displayed in the list;
    this.resource.grid.updateAttachments();

    this.handler.activate();
  }

  public get placeholderText() {
    return this.i18n.t('js.grid.widgets.work_packages_overview.placeholder');
  }

  public get inplaceEditClasses() {
    let classes = 'inplace-editing--container wp-edit-field--display-field wp-table--cell-span -editable';

    if (this.textEmpty) {
      classes += ' -placeholder';
    }

    return classes;
  }

  public get schema() {
    return this.handler.schema;
  }

  public get changeset() {
    return this.handler.changeset;
  }

  public get active() {
    return this.handler.active;
  }

  public get textEmpty() {
    return !this.customText;
  }

  public get isTextEditable() {
    return this.layout.isEditable;
  }

  private setupVariables(initial = false) {
    this.memorizeRawText();
    if (initial) {
      this.handler.initialize(this.resource);
    } else {
      this.handler.reinitialize(this.resource);
    }
    this.memorizeCustomText();
  }

  private memorizeRawText() {
    this.currentRawText = (this.resource.options.text as HalResource).raw;
  }

  private memorizeCustomText() {
    this.customText = this.sanitization.bypassSecurityTrustHtml(this.handler.htmlText);
  }

  private clickedElementIsLinkWithinDisplayContainer(event:any) {
    return this.displayContainer.nativeElement.contains(event.target.closest('a,macro'));
  }
}
