import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JwtAuthenticationGuard } from '../auth/authentication.guard.js';
import { RequireTrustedRoles, TrustedRolesGuard } from '../auth/trusted-roles.guard.js';
import {
  CreateLocationDto,
  LocationParamsDto,
  LocationResponseDto,
  UpdateLocationDto,
} from './dto/location.dto.js';
import { LocationsService } from './locations.service.js';

@ApiTags('Locations')
@ApiBearerAuth('JWT-auth')
@Controller('locations')
@UseGuards(JwtAuthenticationGuard)
export class LocationsController {
  constructor(private readonly locationsService: LocationsService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sách tất cả vị trí kệ kho' })
  @ApiOkResponse({ description: 'Danh sách vị trí kệ kho.', type: [LocationResponseDto] })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  async findAll(): Promise<LocationResponseDto[]> {
    return this.locationsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiết vị trí theo UUID hoặc barcode vị trí' })
  @ApiOkResponse({ description: 'Thông tin vị trí kệ kho.', type: LocationResponseDto })
  @ApiNotFoundResponse({ description: 'Vị trí không tồn tại.' })
  async findOne(@Param() params: LocationParamsDto): Promise<LocationResponseDto> {
    return this.locationsService.findById(params.id);
  }

  @Post()
  @UseGuards(TrustedRolesGuard)
  @RequireTrustedRoles('ADMIN', 'MANAGER')
  @ApiOperation({ summary: 'Tạo vị trí kệ kho mới' })
  @ApiCreatedResponse({ description: 'Vị trí đã được tạo.', type: LocationResponseDto })
  @ApiConflictResponse({ description: 'Mã vạch vị trí đã tồn tại.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN hoặc MANAGER.' })
  async create(@Body() dto: CreateLocationDto): Promise<LocationResponseDto> {
    return this.locationsService.create(dto);
  }

  @Put(':id')
  @UseGuards(TrustedRolesGuard)
  @RequireTrustedRoles('ADMIN', 'MANAGER')
  @ApiOperation({ summary: 'Cập nhật thông tin vị trí kệ kho' })
  @ApiOkResponse({ description: 'Vị trí đã được cập nhật.', type: LocationResponseDto })
  @ApiNotFoundResponse({ description: 'Vị trí không tồn tại.' })
  @ApiConflictResponse({ description: 'Mã vạch vị trí bị trùng.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN hoặc MANAGER.' })
  async update(
    @Param() params: LocationParamsDto,
    @Body() dto: UpdateLocationDto,
  ): Promise<LocationResponseDto> {
    return this.locationsService.update(params.id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(TrustedRolesGuard)
  @RequireTrustedRoles('ADMIN')
  @ApiOperation({ summary: 'Xóa vị trí kệ kho (chỉ khi không có tham chiếu)' })
  @ApiOkResponse({ description: 'Vị trí đã bị xóa.' })
  @ApiNotFoundResponse({ description: 'Vị trí không tồn tại.' })
  @ApiConflictResponse({ description: 'Vị trí đang có tồn kho hoặc phiếu tham chiếu.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN.' })
  async remove(@Param() params: LocationParamsDto): Promise<void> {
    await this.locationsService.remove(params.id);
  }
}
